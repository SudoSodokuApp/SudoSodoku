import XCTest
@testable import SudoSudoku

final class UserDataResetTests: XCTestCase {

    private let currentFileName = "save_data_v4.json"
    private let suiteName = "UserDataResetTests"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: saveURL())
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: saveURL())
        super.tearDown()
    }

    func testWipeAllDataResetsRecordsRatingAndPersists() throws {
        let manager = StorageManager()
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        let record = makeRecord()
        manager.saveGame(record)
        manager.recordRatingGain(300, forGame: record.id)
        XCTAssertEqual(manager.userRating, 1500)
        XCTAssertEqual(manager.records.count, 1)

        manager.wipeAllData()

        XCTAssertTrue(manager.records.isEmpty)
        XCTAssertEqual(manager.userRating, 1200)

        let data = try Data(contentsOf: saveURL())
        let container = try JSONDecoder().decode(StorageManager.StorageContainer.self, from: data)
        XCTAssertEqual(container.rating, 1200, "The wipe must be persisted, not just in-memory")
        XCTAssertTrue(container.records.isEmpty)
        XCTAssertEqual(container.ratingLedger, RatingLedger(), "The ledger must be emptied too")
    }

    func testWipeReportsEveryDeletionSoICloudCannotRestoreIt() {
        let manager = StorageManager()
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        let record = makeRecord()
        manager.saveGame(record)
        manager.recordRatingGain(40, forGame: record.id)
        let spy = SyncSpy()
        manager.syncDelegate = spy

        manager.wipeAllData()

        XCTAssertEqual(spy.changes.last?.deletedRecordIDs, [record.id])
        XCTAssertEqual(spy.changes.last?.deletedRatingKeys, [.gain(record.id.uuidString)])
    }

    func testAchievementResetReportsClearedUnlocks() {
        let manager = AchievementManager(defaults: defaults)
        manager.unlockIncidentReported()
        var removed: [String] = []
        manager.onUnlockSetChange = { _, cleared in removed = cleared }

        manager.resetAllProgress()

        XCTAssertEqual(removed, [Achievement.incidentReported.rawValue])
    }

    func testAchievementResetClearsLocalStateAndAllowsReUnlock() {
        let manager = AchievementManager(defaults: defaults)
        manager.unlockIncidentReported()
        XCTAssertTrue(manager.isUnlocked(.incidentReported))

        manager.resetAllProgress()

        XCTAssertFalse(manager.isUnlocked(.incidentReported))
        XCTAssertNil(defaults.stringArray(forKey: "pendingAchievementReports"),
                     "The offline report queue must be cleared too")

        XCTAssertEqual(manager.unlockIncidentReported(), [.incidentReported],
                       "After a reset the unlock must announce again")
    }

    // MARK: - Fixtures

    private final class SyncSpy: SaveDataSyncDelegate {
        var changes: [SaveDataChange] = []
        func storageDidChange(_ change: SaveDataChange) { changes.append(change) }
    }

    private func saveURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(currentFileName)
    }

    private func makeRecord() -> GameRecord {
        GameRecord(
            id: UUID(),
            startTime: Date(),
            lastPlayedTime: Date(),
            difficulty: "EASY",
            difficultyIndex: 10,
            initialBoard: Array(repeating: 0, count: 81),
            solution: Array(repeating: 1, count: 81),
            playerBoard: Array(repeating: 0, count: 81),
            playerNotes: nil,
            isSolved: true,
            ratingChange: 10
        )
    }
}
