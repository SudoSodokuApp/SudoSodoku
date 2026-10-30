import Foundation
import Combine

/// One batch of local edits, reported so iCloud sync can push them.
struct SaveDataChange {
    var savedRecordIDs: [UUID] = []
    var deletedRecordIDs: [UUID] = []
    var savedRatingKeys: [RatingLedger.Key] = []
    var deletedRatingKeys: [RatingLedger.Key] = []
}

protocol SaveDataSyncDelegate: AnyObject {
    func storageDidChange(_ change: SaveDataChange)
}

class StorageManager: ObservableObject {
    static let shared = StorageManager()
    @Published var records: [GameRecord] = []
    @Published var userRating: Int = RatingLedger.startingRating

    /// Source of truth for `userRating`, which is always `ratingLedger.rating`.
    private(set) var ratingLedger = RatingLedger()

    /// Told about every local edit. Nil when sync never started (tests,
    /// no iCloud entitlement); remote edits applied through `applyRemote`
    /// are not echoed back.
    weak var syncDelegate: SaveDataSyncDelegate?

    private let currentFileName = "save_data_v4.json"
    private let legacyFileNames = ["save_data_v3.json", "save_data_v2.json", "save_data.json"]

    init() { loadData() }

    private func getFileURL(name: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(name)
    }

    struct StorageContainer: Codable {
        /// Still written (as the ledger's total) so an older app version
        /// reading this file shows the right rating.
        let rating: Int
        let records: [GameRecord]
        /// Absent in saves from before iCloud sync.
        var ratingLedger: RatingLedger? = nil
    }

    func saveGame(_ record: GameRecord) {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
        } else {
            records.insert(record, at: 0)
        }
        persist(SaveDataChange(savedRecordIDs: [record.id]))
    }

    func toggleFavorite(for id: UUID) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        records[index].isFavorite.toggle()
        if records[index].isFavorite { records[index].isArchived = true }
        persist(SaveDataChange(savedRecordIDs: [id]))
    }

    func setArchived(for id: UUID, isArchived: Bool) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        records[index].isArchived = isArchived
        if !isArchived { records[index].isFavorite = false }
        persist(SaveDataChange(savedRecordIDs: [id]))
    }

    func batchDelete(ids: Set<UUID>) {
        let removed = records.filter { ids.contains($0.id) }.map(\.id)
        records.removeAll { ids.contains($0.id) }
        persist(SaveDataChange(deletedRecordIDs: removed))
    }

    func batchFavorite(ids: Set<UUID>) {
        var changed: [UUID] = []
        for index in records.indices where ids.contains(records[index].id) {
            records[index].isFavorite = true
            records[index].isArchived = true
            changed.append(records[index].id)
        }
        persist(SaveDataChange(savedRecordIDs: changed))
    }

    func deleteRecord(id: UUID) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }
        records.remove(at: index)
        persist(SaveDataChange(deletedRecordIDs: [id]))
    }

    /// Books the points one solve earned. Keyed by the game, so the same
    /// solve arriving from two devices still counts once.
    func recordRatingGain(_ points: Int, forGame id: UUID) {
        let key = RatingLedger.Key.gain(id.uuidString)
        ratingLedger.set(points, for: key)
        userRating = ratingLedger.rating
        persist(SaveDataChange(savedRatingKeys: [key]))
    }

    /// Factory reset: drops every record and returns the rating to the
    /// starting 1200. Persists immediately so legacy files can't resurrect
    /// the old state on next launch, and reports the deletions so iCloud
    /// can't either.
    func wipeAllData() {
        let change = SaveDataChange(
            deletedRecordIDs: records.map(\.id),
            deletedRatingKeys: ratingLedger.keys
        )
        records = []
        ratingLedger = RatingLedger()
        userRating = ratingLedger.rating
        persist(change)
    }

    // MARK: - iCloud

    /// Folds changes fetched from iCloud into local data. `pendingRecordIDs`
    /// are games this device edited but has not uploaded yet.
    func applyRemote(
        records incoming: [GameRecord],
        deletedRecordIDs: Set<UUID>,
        ratingLedger remoteLedger: RatingLedger,
        deletedRatingKeys: Set<RatingLedger.Key>,
        pendingRecordIDs: Set<UUID>
    ) {
        if !incoming.isEmpty || !deletedRecordIDs.isEmpty {
            records = SaveDataMerge.merge(
                local: records,
                incoming: incoming,
                deleted: deletedRecordIDs,
                pending: pendingRecordIDs
            )
        }
        var ledger = ratingLedger.merging(remoteLedger)
        deletedRatingKeys.forEach { ledger.remove($0) }
        if ledger != ratingLedger {
            ratingLedger = ledger
            userRating = ledger.rating
        }
        persist(nil)
    }

    // MARK: - Disk

    func loadData() {
        let currentURL = getFileURL(name: currentFileName)

        if FileManager.default.fileExists(atPath: currentURL.path),
           let data = try? Data(contentsOf: currentURL),
           let decoded = try? JSONDecoder().decode(StorageContainer.self, from: data) {
            if let ledger = decoded.ratingLedger {
                applyLoadedData(records: decoded.records, ledger: ledger)
            } else {
                // First launch with sync: the baseline id must be written
                // now, or every launch would mint a new one.
                applyLoadedData(records: decoded.records, ledger: .migrating(rating: decoded.rating))
                persist(nil)
            }
            return
        }

        for legacyName in legacyFileNames {
            let legacyURL = getFileURL(name: legacyName)
            guard FileManager.default.fileExists(atPath: legacyURL.path),
                  let data = try? Data(contentsOf: legacyURL),
                  let decoded = try? JSONDecoder().decode(StorageContainer.self, from: data) else { continue }

            var migratedRecords = decoded.records
            for index in migratedRecords.indices {
                migratedRecords[index].isArchived = true
            }
            applyLoadedData(records: migratedRecords, ledger: .migrating(rating: decoded.rating))
            persist(nil)
            return
        }
    }

    /// The ledger is set synchronously (persist reads it); the published
    /// values follow on the main queue as before.
    private func applyLoadedData(records: [GameRecord], ledger: RatingLedger) {
        let sorted = records.sorted { $0.lastPlayedTime > $1.lastPlayedTime }
        ratingLedger = ledger
        loadedRecords = sorted
        DispatchQueue.main.async {
            self.records = sorted
            self.userRating = ledger.rating
            self.loadedRecords = nil
        }
    }

    /// Records read from disk but not yet published, so a persist in the
    /// same run-loop turn as loading doesn't write an empty list.
    private var loadedRecords: [GameRecord]?

    private func persist(_ change: SaveDataChange?) {
        let container = StorageContainer(
            rating: ratingLedger.rating,
            records: loadedRecords ?? records,
            ratingLedger: ratingLedger
        )
        if let data = try? JSONEncoder().encode(container) {
            try? data.write(to: getFileURL(name: currentFileName), options: .atomic)
        }
        if let change { syncDelegate?.storageDidChange(change) }
    }
}
