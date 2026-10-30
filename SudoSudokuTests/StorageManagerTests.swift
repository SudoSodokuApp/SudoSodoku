import XCTest
@testable import SudoSudoku

final class StorageManagerTests: XCTestCase {

    private let currentFileName = "save_data_v4.json"
    private let legacyFileNames = ["save_data_v3.json", "save_data_v2.json", "save_data.json"]

    override func setUp() {
        super.setUp()
        removeAllSaveFiles()
    }

    override func tearDown() {
        removeAllSaveFiles()
        super.tearDown()
    }

    // MARK: - Fresh start

    func testFreshInstallStartsWithDefaults() {
        let manager = StorageManager()
        waitForMainQueue()

        XCTAssertTrue(manager.records.isEmpty)
        XCTAssertEqual(manager.userRating, 1200, "Default ELO must be 1200")
    }

    // MARK: - Persistence roundtrip

    func testSaveGamePersistsRecordToDisk() throws {
        let manager = StorageManager()
        waitForMainQueue()

        let record = makeRecord()
        manager.saveGame(record)

        let container = try loadContainerFromDisk()
        XCTAssertEqual(container.records.count, 1)
        XCTAssertEqual(container.records[0].id, record.id)
        XCTAssertEqual(container.records[0].difficulty, "EASY")
    }

    func testSaveGameUpdatesExistingRecordInsteadOfDuplicating() throws {
        let manager = StorageManager()
        waitForMainQueue()

        var record = makeRecord()
        manager.saveGame(record)
        record.isSolved = true
        manager.saveGame(record)

        let container = try loadContainerFromDisk()
        XCTAssertEqual(container.records.count, 1, "Saving the same id twice must not duplicate")
        XCTAssertTrue(container.records[0].isSolved)
    }

    func testUpdateUserRatingAccumulatesAndPersists() throws {
        let manager = StorageManager()
        waitForMainQueue()

        manager.recordRatingGain(50, forGame: UUID())
        XCTAssertEqual(manager.userRating, 1250)

        let container = try loadContainerFromDisk()
        XCTAssertEqual(container.rating, 1250, "The plain rating is still written for older app versions")
        XCTAssertEqual(container.ratingLedger?.rating, 1250)
    }

    func testRatingGainForTheSameGameCountsOnce() {
        let manager = StorageManager()
        waitForMainQueue()

        let id = UUID()
        manager.recordRatingGain(30, forGame: id)
        manager.recordRatingGain(30, forGame: id)

        XCTAssertEqual(manager.userRating, 1230)
    }

    // MARK: - Rating ledger migration

    func testPreLedgerSaveKeepsItsRatingAsABaseline() throws {
        let old = StorageManager.StorageContainer(rating: 1640, records: [makeRecord()])
        try JSONEncoder().encode(old).write(to: fileURL(name: currentFileName))

        let manager = StorageManager()
        waitUntil { manager.userRating != 1200 }

        XCTAssertEqual(manager.userRating, 1640)
        XCTAssertEqual(manager.records.count, 1)
        let ledger = try XCTUnwrap(loadContainerFromDisk().ratingLedger,
                                   "Migration must write the ledger so its baseline id stays stable")
        XCTAssertEqual(Array(ledger.baselines.values), [440])
        XCTAssertEqual(try loadContainerFromDisk().records.count, 1,
                       "Migrating must not write an empty record list")
    }

    func testLegacyMigrationWritesTheMigratedRecordsNotAnEmptyFile() throws {
        let legacy = StorageManager.StorageContainer(rating: 1300, records: [makeRecord()])
        try JSONEncoder().encode(legacy).write(to: fileURL(name: "save_data_v2.json"))

        _ = StorageManager()

        XCTAssertEqual(try loadContainerFromDisk().records.count, 1)
    }

    // MARK: - iCloud hooks

    func testLocalEditsAreReportedToSync() {
        let manager = StorageManager()
        waitForMainQueue()
        let spy = SyncSpy()
        manager.syncDelegate = spy

        let record = makeRecord()
        manager.saveGame(record)
        manager.toggleFavorite(for: record.id)
        manager.recordRatingGain(12, forGame: record.id)
        manager.deleteRecord(id: record.id)

        XCTAssertEqual(spy.changes.map(\.savedRecordIDs), [[record.id], [record.id], [], []])
        XCTAssertEqual(spy.changes[2].savedRatingKeys, [.gain(record.id.uuidString)])
        XCTAssertEqual(spy.changes[3].deletedRecordIDs, [record.id])
    }

    func testApplyRemoteMergesWithoutEchoingBackToSync() throws {
        let manager = StorageManager()
        waitForMainQueue()
        let local = makeRecord()
        manager.saveGame(local)
        manager.recordRatingGain(20, forGame: local.id)
        let spy = SyncSpy()
        manager.syncDelegate = spy

        let remote = makeRecord()
        var remoteLedger = RatingLedger()
        remoteLedger.set(15, for: .gain(remote.id.uuidString))
        manager.applyRemote(
            records: [remote],
            deletedRecordIDs: [local.id],
            ratingLedger: remoteLedger,
            deletedRatingKeys: [],
            pendingRecordIDs: []
        )

        XCTAssertEqual(manager.records.map(\.id), [remote.id])
        XCTAssertEqual(manager.userRating, 1235, "Both devices' gains must count")
        XCTAssertTrue(spy.changes.isEmpty, "Remote changes must not be re-uploaded")
        XCTAssertEqual(try loadContainerFromDisk().records.map(\.id), [remote.id])
    }

    // MARK: - Legacy migration

    func testLegacySaveFileIsMigratedToCurrentFormat() throws {
        let legacyRecord = makeRecord()
        let legacyContainer = StorageManager.StorageContainer(rating: 1500, records: [legacyRecord])
        let data = try JSONEncoder().encode(legacyContainer)
        try data.write(to: fileURL(name: "save_data_v3.json"))

        let manager = StorageManager()
        waitUntil { !manager.records.isEmpty }

        XCTAssertEqual(manager.userRating, 1500, "Rating must survive migration")
        XCTAssertEqual(manager.records.count, 1)
        XCTAssertEqual(manager.records[0].id, legacyRecord.id)
        XCTAssertTrue(manager.records[0].isArchived, "Migrated records must be marked archived")

        XCTAssertTrue(
            FileManager.default.fileExists(atPath: fileURL(name: currentFileName).path),
            "Migration must write the v4 save file"
        )
    }

    func testCurrentFormatTakesPrecedenceOverLegacyFiles() throws {
        let currentContainer = StorageManager.StorageContainer(rating: 1800, records: [])
        try JSONEncoder().encode(currentContainer).write(to: fileURL(name: currentFileName))

        let legacyContainer = StorageManager.StorageContainer(rating: 1300, records: [makeRecord()])
        try JSONEncoder().encode(legacyContainer).write(to: fileURL(name: "save_data_v2.json"))

        let manager = StorageManager()
        waitUntil { manager.userRating != 1200 }

        XCTAssertEqual(manager.userRating, 1800, "v4 data must win over legacy files")
        XCTAssertTrue(manager.records.isEmpty)
    }

    // MARK: - Helpers

    private final class SyncSpy: SaveDataSyncDelegate {
        var changes: [SaveDataChange] = []
        func storageDidChange(_ change: SaveDataChange) { changes.append(change) }
    }

    private func makeRecord() -> GameRecord {
        var solution = Array(repeating: 0, count: 81)
        for index in 0..<81 {
            solution[index] = (index % 9) + 1
        }
        var initial = solution
        initial[0] = 0

        return GameRecord(
            id: UUID(),
            startTime: Date(timeIntervalSince1970: 1_000_000),
            lastPlayedTime: Date(timeIntervalSince1970: 1_000_100),
            difficulty: "EASY",
            difficultyIndex: 10,
            initialBoard: initial,
            solution: solution,
            playerBoard: Array(repeating: 0, count: 81),
            playerNotes: Array(repeating: [], count: 81),
            isSolved: false,
            ratingChange: nil
        )
    }

    private func fileURL(name: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(name)
    }

    private func loadContainerFromDisk() throws -> StorageManager.StorageContainer {
        let data = try Data(contentsOf: fileURL(name: currentFileName))
        return try JSONDecoder().decode(StorageManager.StorageContainer.self, from: data)
    }

    private func removeAllSaveFiles() {
        for name in [currentFileName] + legacyFileNames {
            try? FileManager.default.removeItem(at: fileURL(name: name))
        }
    }

    /// StorageManager publishes loaded data via DispatchQueue.main.async;
    /// spin the main run loop until the condition holds or the timeout expires.
    private func waitUntil(timeout: TimeInterval = 2.0, _ condition: () -> Bool) {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        XCTAssertTrue(condition(), "Timed out waiting for condition")
    }

    private func waitForMainQueue() {
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }
}
