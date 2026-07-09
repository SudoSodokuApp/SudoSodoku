import XCTest
@testable import SudoSodoku

/// A solved record is immutable history: stats, personal bests, and recent
/// completions all derive from it. Restarting or replaying a solved puzzle
/// must fork a fresh record, never overwrite the original in storage.
final class SolvedRecordImmutabilityTests: XCTestCase {

    private var fixtureIDs: [UUID] = []

    override func tearDown() {
        for id in fixtureIDs {
            StorageManager.shared.deleteRecord(id: id)
        }
        fixtureIDs = []
        super.tearDown()
    }

    func testRestartedCopyMintsNewIdentity() {
        let original = makeRecord(emptyIndices: [0], solved: true, playDuration: 120)
        let restarted = original.restartedCopy()

        XCTAssertNotEqual(restarted.id, original.id,
                          "A restart must fork: the same id would make autosaves overwrite the solved original")
        XCTAssertFalse(restarted.isSolved)
        XCTAssertNil(restarted.ratingChange)
        XCTAssertEqual(restarted.playDuration, 0)
        XCTAssertEqual(restarted.undoCount, 0)
        XCTAssertEqual(restarted.playerBoard, Array(repeating: 0, count: 81))
        XCTAssertEqual(restarted.initialBoard, original.initialBoard, "Same puzzle")
        XCTAssertEqual(restarted.solution, original.solution)
    }

    func testReplayOfSolvedGameForksAndPreservesTheSolve() {
        let solved = makeRecord(emptyIndices: [0], solved: true, playDuration: 300)
        fixtureIDs.append(solved.id)
        StorageManager.shared.saveGame(solved)

        let game = SudokuGame()
        game.loadFromRecord(solved)
        game.replayCurrentGame()
        if let forkedID = game.currentRecordID { fixtureIDs.append(forkedID) }

        XCTAssertNotEqual(game.currentRecordID, solved.id,
                          "Replaying a solved game must fork a new record")

        let storedOriginal = StorageManager.shared.records.first { $0.id == solved.id }
        XCTAssertEqual(storedOriginal?.isSolved, true,
                       "The historical solve must survive the replay")
        XCTAssertEqual(storedOriginal?.playDuration ?? -1, 300, accuracy: 1.0)

        let fork = StorageManager.shared.records.first { $0.id == game.currentRecordID }
        XCTAssertEqual(fork?.isSolved, false, "The fork starts as a fresh attempt")
    }

    func testReplayOfUnsolvedGameStaysInPlace() {
        let inProgress = makeRecord(emptyIndices: [0, 1], solved: false)
        fixtureIDs.append(inProgress.id)
        StorageManager.shared.saveGame(inProgress)

        let game = SudokuGame()
        game.loadFromRecord(inProgress)
        game.replayCurrentGame()

        XCTAssertEqual(game.currentRecordID, inProgress.id,
                       "Retrying an unsolved game is an in-place reset, not a fork")
    }

    // MARK: - Fixtures

    /// A valid completed sudoku via the row-shift pattern.
    private func solutionValue(at index: Int) -> Int {
        let row = index / 9
        let col = index % 9
        return (row * 3 + row / 3 + col) % 9 + 1
    }

    private func makeRecord(emptyIndices: [Int], solved: Bool, playDuration: TimeInterval = 0) -> GameRecord {
        let solution = (0..<81).map { solutionValue(at: $0) }
        var initial = solution
        for index in emptyIndices { initial[index] = 0 }
        var player = Array(repeating: 0, count: 81)
        if solved {
            for index in emptyIndices { player[index] = solution[index] }
        }

        return GameRecord(
            id: UUID(),
            startTime: Date(),
            lastPlayedTime: Date(),
            difficulty: "EASY",
            difficultyIndex: 10,
            initialBoard: initial,
            solution: solution,
            playerBoard: player,
            playerNotes: Array(repeating: [], count: 81),
            isSolved: solved,
            ratingChange: solved ? 10 : nil,
            playDuration: playDuration
        )
    }
}
