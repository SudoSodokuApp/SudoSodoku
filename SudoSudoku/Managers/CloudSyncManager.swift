import CloudKit
import Foundation
import os
import UIKit

/// Mirrors save data into the player's private iCloud database with
/// CKSyncEngine, so a new or second iPhone gets its history, rating and
/// achievements back. The local JSON file stays the source of truth the UI
/// reads; this class only translates between it and CloudKit records. The
/// private database belongs to the player's Apple Account — the developer
/// can't read it.
///
/// Record layout, all in one custom zone:
/// - `Game`: one per `GameRecord`, named by its UUID, JSON in `payload`
/// - `RatingEntry`: one per `RatingLedger` line, `points`
/// - `Achievement`: one per unlocked achievement, no fields
final class CloudSyncManager: CKSyncEngineDelegate, SaveDataSyncDelegate {
    static let containerIdentifier = "iCloud.dev.kaichen.sudoku.app"
    private(set) static var shared: CloudSyncManager?

    private static let zoneID = CKRecordZone.ID(zoneName: "SaveData")
    private static let achievementPrefix = "achievement."

    private enum RecordType {
        static let game = "Game"
        static let rating = "RatingEntry"
        static let achievement = "Achievement"
    }

    /// Engine progress plus the last server copy of each record's system
    /// fields (change tag), so edits don't round-trip as conflicts.
    private struct PersistedState: Codable {
        var engineState: CKSyncEngine.State.Serialization?
        var systemFields: [String: Data] = [:]
    }

    private let storage: StorageManager
    private let achievements: AchievementManager
    private var persisted: PersistedState
    private var engine: CKSyncEngine?
    private let logger = Logger(subsystem: AppConstants.bundleIdentifier, category: "CloudSync")

    /// Starts sync for the app. Skipped under unit tests, which run inside
    /// the app host and must not touch the developer's iCloud account.
    static func startForApp() {
        guard shared == nil,
              ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        let manager = CloudSyncManager(storage: .shared, achievements: .shared)
        shared = manager
        // After StorageManager publishes what it loaded from disk (it does
        // so on the next main-queue turn), so the first upload sees it.
        DispatchQueue.main.async { manager.start() }
    }

    private init(storage: StorageManager, achievements: AchievementManager) {
        self.storage = storage
        self.achievements = achievements
        self.persisted = Self.loadPersistedState()
    }

    private func start() {
        let configuration = CKSyncEngine.Configuration(
            database: CKContainer(identifier: Self.containerIdentifier).privateCloudDatabase,
            stateSerialization: persisted.engineState,
            delegate: self
        )
        let engine = CKSyncEngine(configuration)
        self.engine = engine

        storage.syncDelegate = self
        achievements.onUnlockSetChange = { [weak self] unlocked, removed in
            self?.enqueue(
                saves: unlocked.map { Self.achievementRecordID($0) },
                deletes: removed.map { Self.achievementRecordID($0) }
            )
        }
        // Silent pushes tell the engine another device changed something.
        UIApplication.shared.registerForRemoteNotifications()

        // No saved engine state means this install never synced: upload
        // everything it has. The engine merges with what's on the server.
        if persisted.engineState == nil {
            enqueueEverything()
        }
    }

    // MARK: - Local changes → iCloud

    func storageDidChange(_ change: SaveDataChange) {
        enqueue(
            saves: change.savedRecordIDs.map(Self.gameRecordID)
                + change.savedRatingKeys.map(Self.ratingRecordID),
            deletes: change.deletedRecordIDs.map(Self.gameRecordID)
                + change.deletedRatingKeys.map(Self.ratingRecordID)
        )
    }

    private func enqueue(saves: [CKRecord.ID], deletes: [CKRecord.ID]) {
        guard let engine else { return }
        engine.state.add(pendingRecordZoneChanges:
            saves.map { .saveRecord($0) } + deletes.map { .deleteRecord($0) })
    }

    private func enqueueEverything() {
        guard let engine else { return }
        engine.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: Self.zoneID))])
        enqueue(
            saves: storage.records.map { Self.gameRecordID($0.id) }
                + storage.ratingLedger.keys.map(Self.ratingRecordID)
                + achievements.unlockedIDs.map(Self.achievementRecordID),
            deletes: []
        )
    }

    // MARK: - CKSyncEngineDelegate

    func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        switch event {
        case .stateUpdate(let update):
            persisted.engineState = update.stateSerialization
            savePersistedState()

        case .accountChange(let change):
            handleAccountChange(change)

        case .fetchedDatabaseChanges(let changes):
            // The zone vanished (another device's debug wipe, or the player
            // deleted the app's iCloud data in Settings). Local history is
            // the only copy left, so put it back rather than delete it.
            if changes.deletions.contains(where: { $0.zoneID == Self.zoneID }) {
                persisted.systemFields = [:]
                savePersistedState()
                enqueueEverything()
            }

        case .fetchedRecordZoneChanges(let changes):
            ingest(
                changes.modifications.map(\.record),
                deletions: changes.deletions.map { ($0.recordID, $0.recordType) }
            )

        case .sentRecordZoneChanges(let sent):
            handleSent(sent)

        case .sentDatabaseChanges, .willFetchChanges, .willFetchRecordZoneChanges,
             .didFetchRecordZoneChanges, .didFetchChanges, .willSendChanges, .didSendChanges:
            break

        @unknown default:
            logger.info("Unhandled sync event: \(String(describing: event))")
        }
    }

    func nextRecordZoneChangeBatch(
        _ context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {
        let changes = syncEngine.state.pendingRecordZoneChanges.filter { context.options.scope.contains($0) }
        return await CKSyncEngine.RecordZoneChangeBatch(pendingChanges: changes) { recordID in
            await self.makeRecord(for: recordID)
        }
    }

    // MARK: - iCloud → local

    /// Decodes fetched (or conflicting server) records and hands them to
    /// the local stores in one batch each.
    private func ingest(_ records: [CKRecord], deletions: [(CKRecord.ID, CKRecord.RecordType)]) {
        var games: [GameRecord] = []
        var ledger = RatingLedger()
        var unlocked = Set<String>()
        var deletedGames = Set<UUID>()
        var deletedRatingKeys = Set<RatingLedger.Key>()
        var lockedAgain = Set<String>()

        for record in records {
            let name = record.recordID.recordName
            persisted.systemFields[name] = record.encodedSystemFields
            switch record.recordType {
            case RecordType.game:
                if let data = record["payload"] as? Data,
                   let game = try? JSONDecoder().decode(GameRecord.self, from: data) {
                    games.append(game)
                }
            case RecordType.rating:
                if let key = RatingLedger.Key(recordName: name), let points = record["points"] as? Int {
                    ledger.set(points, for: key)
                }
            case RecordType.achievement:
                unlocked.insert(String(name.dropFirst(Self.achievementPrefix.count)))
            default:
                break
            }
        }

        for (recordID, recordType) in deletions {
            let name = recordID.recordName
            persisted.systemFields[name] = nil
            switch recordType {
            case RecordType.game:
                if let id = UUID(uuidString: name) { deletedGames.insert(id) }
            case RecordType.rating:
                if let key = RatingLedger.Key(recordName: name) { deletedRatingKeys.insert(key) }
            case RecordType.achievement:
                lockedAgain.insert(String(name.dropFirst(Self.achievementPrefix.count)))
            default:
                break
            }
        }

        storage.applyRemote(
            records: games,
            deletedRecordIDs: deletedGames,
            ratingLedger: ledger,
            deletedRatingKeys: deletedRatingKeys,
            pendingRecordIDs: pendingGameIDs()
        )
        achievements.applyRemote(unlocked: unlocked, removed: lockedAgain)
        savePersistedState()
    }

    private func handleSent(_ sent: CKSyncEngine.Event.SentRecordZoneChanges) {
        for record in sent.savedRecords {
            persisted.systemFields[record.recordID.recordName] = record.encodedSystemFields
        }
        for recordID in sent.deletedRecordIDs {
            persisted.systemFields[recordID.recordName] = nil
        }

        var retries: [CKRecord.ID] = []
        var zoneMissing = false
        var serverCopies: [CKRecord] = []

        for failure in sent.failedRecordSaves {
            let recordID = failure.record.recordID
            switch failure.error.code {
            case .serverRecordChanged:
                // Another device saved first. Fold its copy in (this device's
                // edit is pending, so it survives unless the server solved
                // the game), then retry on top of the server's change tag.
                if let serverRecord = failure.error.serverRecord {
                    serverCopies.append(serverRecord)
                }
                retries.append(recordID)
            case .zoneNotFound:
                zoneMissing = true
                persisted.systemFields[recordID.recordName] = nil
                retries.append(recordID)
            case .unknownItem:
                // Deleted on the server while we held its change tag.
                persisted.systemFields[recordID.recordName] = nil
                retries.append(recordID)
            case .networkFailure, .networkUnavailable, .zoneBusy, .serviceUnavailable,
                 .notAuthenticated, .operationCancelled, .requestRateLimited:
                break // the engine retries these on its own
            default:
                logger.error("Save failed for \(recordID.recordName): \(failure.error.localizedDescription)")
            }
        }

        if !serverCopies.isEmpty {
            ingest(serverCopies, deletions: [])
        }
        if zoneMissing {
            engine?.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: Self.zoneID))])
        }
        enqueue(saves: retries, deletes: [])
        savePersistedState()
    }

    private func handleAccountChange(_ change: CKSyncEngine.Event.AccountChange) {
        // Local data always stays on the device. Change tags belong to the
        // old account's records, so they go either way.
        persisted.systemFields = [:]
        savePersistedState()
        switch change.changeType {
        case .signIn, .switchAccounts:
            enqueueEverything()
        case .signOut:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Records

    /// The CKRecord for a pending save, or nil when the item no longer
    /// exists locally (the engine then drops the pending save).
    private func makeRecord(for recordID: CKRecord.ID) -> CKRecord? {
        let name = recordID.recordName

        if let id = UUID(uuidString: name) {
            guard let game = storage.records.first(where: { $0.id == id }),
                  let payload = try? JSONEncoder().encode(game) else { return nil }
            let record = blankRecord(type: RecordType.game, id: recordID)
            record["payload"] = payload
            return record
        }

        if let key = RatingLedger.Key(recordName: name) {
            guard let points = storage.ratingLedger.points(for: key) else { return nil }
            let record = blankRecord(type: RecordType.rating, id: recordID)
            record["points"] = points
            return record
        }

        if name.hasPrefix(Self.achievementPrefix) {
            let achievementID = String(name.dropFirst(Self.achievementPrefix.count))
            guard achievements.unlockedIDs.contains(achievementID) else { return nil }
            return blankRecord(type: RecordType.achievement, id: recordID)
        }

        return nil
    }

    /// A record carrying the last known server change tag, if any.
    private func blankRecord(type: CKRecord.RecordType, id: CKRecord.ID) -> CKRecord {
        if let data = persisted.systemFields[id.recordName],
           let coder = try? NSKeyedUnarchiver(forReadingFrom: data) {
            coder.requiresSecureCoding = true
            defer { coder.finishDecoding() }
            if let record = CKRecord(coder: coder) { return record }
        }
        return CKRecord(recordType: type, recordID: id)
    }

    private func pendingGameIDs() -> Set<UUID> {
        guard let engine else { return [] }
        return Set(engine.state.pendingRecordZoneChanges.compactMap { change in
            if case .saveRecord(let recordID) = change { return UUID(uuidString: recordID.recordName) }
            return nil
        })
    }

    private static func gameRecordID(_ id: UUID) -> CKRecord.ID {
        CKRecord.ID(recordName: id.uuidString, zoneID: zoneID)
    }

    private static func ratingRecordID(_ key: RatingLedger.Key) -> CKRecord.ID {
        CKRecord.ID(recordName: key.recordName, zoneID: zoneID)
    }

    private static func achievementRecordID(_ achievementID: String) -> CKRecord.ID {
        CKRecord.ID(recordName: achievementPrefix + achievementID, zoneID: zoneID)
    }

    // MARK: - Persistence

    private static var stateURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("cloud_sync_state.json")
    }

    private static func loadPersistedState() -> PersistedState {
        guard let data = try? Data(contentsOf: stateURL),
              let state = try? JSONDecoder().decode(PersistedState.self, from: data) else {
            return PersistedState()
        }
        return state
    }

    private func savePersistedState() {
        guard let data = try? JSONEncoder().encode(persisted) else { return }
        let url = Self.stateURL
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: url, options: .atomic)
    }
}

private extension CKRecord {
    var encodedSystemFields: Data {
        let coder = NSKeyedArchiver(requiringSecureCoding: true)
        encodeSystemFields(with: coder)
        coder.finishEncoding()
        return coder.encodedData
    }
}
