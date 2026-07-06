import XCTest
@testable import SudoSodoku

final class PlayClockTests: XCTestCase {

    private var fixtureIDs: [UUID] = []

    override func tearDown() {
        // Tests below drive SudokuGame, which persists through the shared
        // StorageManager singleton; remove fixture records so app data in the
        // test host stays clean.
        for id in fixtureIDs {
            StorageManager.shared.deleteRecord(id: id)
        }
        fixtureIDs = []
        super.tearDown()
    }

    // MARK: - Formatting

    func testPlayClockFormatting() {
        XCTAssertEqual(DateFormatting.playClock(0), "00:00")
        XCTAssertEqual(DateFormatting.playClock(754), "12:34")
        XCTAssertEqual(DateFormatting.playClock(3723), "1:02:03")
        XCTAssertEqual(DateFormatting.playClock(-5), "00:00", "Negative intervals must clamp to zero")
    }

    // MARK: - Backward-compatible decoding

    func testRecordWithoutPlayDurationDecodesWithZero() throws {
        // Simulates a save written by 1.0, before playDuration (and the other
        // defaulted fields) existed. Decoding must not throw, or StorageManager
        // would silently discard the archive.
        let json = """
        {
            "id": "\(UUID().uuidString)",
            "startTime": 0,
            "lastPlayedTime": 0,
            "difficulty": "EASY",
            "difficultyIndex": 10,
            "initialBoard": \(Array(repeating: 0, count: 81)),
            "solution": \(Array(repeating: 1, count: 81)),
            "playerBoard": \(Array(repeating: 0, count: 81)),
            "isSolved": false
        }
        """
        let record = try JSONDecoder().decode(GameRecord.self, from: Data(json.utf8))
        XCTAssertEqual(record.playDuration, 0)
        XCTAssertEqual(record.undoCount, 0)
        XCTAssertFalse(record.isArchived)
        XCTAssertFalse(record.isFavorite)
        XCTAssertNil(record.playerNotes)
    }

    func testPlayDurationSurvivesEncodeDecodeRoundtrip() throws {
        var record = makeRecord(emptyIndices: [0])
        record.playDuration = 421.5
        let data = try JSONEncoder().encode(record)
        let decoded = try JSONDecoder().decode(GameRecord.self, from: data)
        XCTAssertEqual(decoded.playDuration, 421.5)
    }

    // MARK: - Clock accumulation

    func testClockAccumulatesPausesAndResumes() {
        let game = SudokuGame()
        let record = makeRecord(emptyIndices: [0, 1], playDuration: 300)
        let t0 = Date()
        game.loadFromRecord(record)

        XCTAssertEqual(game.playDuration(at: t0.addingTimeInterval(10)), 310, accuracy: 1.0,
                       "Loading an in-progress record must resume from its saved duration")

        game.pauseClock(at: t0.addingTimeInterval(10))
        XCTAssertEqual(game.playDuration(at: t0.addingTimeInterval(100)), 310, accuracy: 1.0,
                       "A paused clock must not advance")

        game.resumeClock(at: t0.addingTimeInterval(100))
        XCTAssertEqual(game.playDuration(at: t0.addingTimeInterval(130)), 340, accuracy: 1.0,
                       "Resuming must continue from the paused total")
    }

    func testSolvedRecordLoadsWithFrozenClock() {
        let game = SudokuGame()
        var record = makeRecord(emptyIndices: [], playDuration: 250)
        record.isSolved = true
        game.loadFromRecord(record)

        XCTAssertEqual(game.playDuration(at: Date().addingTimeInterval(3600)), 250,
                       "Solved records must load with a stopped clock")

        game.resumeClock()
        XCTAssertEqual(game.playDuration(at: Date().addingTimeInterval(3600)), 250,
                       "resumeClock must be a no-op on a solved game")
    }

    func testReplayResetsClock() {
        let game = SudokuGame()
        let record = makeRecord(emptyIndices: [0], playDuration: 500)
        fixtureIDs.append(record.id)
        game.loadFromRecord(record)

        game.replayCurrentGame()
        XCTAssertEqual(game.playDuration(at: Date()), 0, accuracy: 1.0,
                       "Replay must reset the clock to zero")
    }

    func testVictoryFreezesClockAndPersistsDuration() {
        let game = SudokuGame()
        let record = makeRecord(emptyIndices: [0], playDuration: 60)
        fixtureIDs.append(record.id)
        game.loadFromRecord(record)

        game.selectCell(at: 0)
        game.inputNumber(solutionValue(at: 0))

        XCTAssertTrue(game.isSolved)
        let frozen = game.playDuration(at: Date().addingTimeInterval(3600))
        XCTAssertEqual(frozen, 60, accuracy: 1.0, "Victory must stop the clock")

        let saved = StorageManager.shared.records.first { $0.id == record.id }
        XCTAssertNotNil(saved)
        XCTAssertEqual(saved?.playDuration ?? -1, 60, accuracy: 1.0,
                       "Final duration must be written to the record")
    }

    // MARK: - Fixtures

    /// A valid completed sudoku via the row-shift pattern.
    private func solutionValue(at index: Int) -> Int {
        let row = index / 9
        let col = index % 9
        return (row * 3 + row / 3 + col) % 9 + 1
    }

    private func makeRecord(emptyIndices: [Int], playDuration: TimeInterval = 0) -> GameRecord {
        let solution = (0..<81).map { solutionValue(at: $0) }
        var initial = solution
        for index in emptyIndices { initial[index] = 0 }

        return GameRecord(
            id: UUID(),
            startTime: Date(),
            lastPlayedTime: Date(),
            difficulty: "EASY",
            difficultyIndex: 10,
            initialBoard: initial,
            solution: solution,
            playerBoard: Array(repeating: 0, count: 81),
            playerNotes: Array(repeating: [], count: 81),
            isSolved: false,
            ratingChange: nil,
            playDuration: playDuration
        )
    }
}
