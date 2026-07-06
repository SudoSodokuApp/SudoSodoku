import XCTest
@testable import SudoSodoku

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

        manager.updateUserRating(add: 50)
        XCTAssertEqual(manager.userRating, 1250)

        let container = try loadContainerFromDisk()
        XCTAssertEqual(container.rating, 1250)
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
