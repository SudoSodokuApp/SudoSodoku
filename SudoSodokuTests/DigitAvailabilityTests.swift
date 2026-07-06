import XCTest
@testable import SudoSodoku

final class DigitAvailabilityTests: XCTestCase {

    private var fixtureIDs: [UUID] = []

    override func tearDown() {
        for id in fixtureIDs {
            StorageManager.shared.deleteRecord(id: id)
        }
        fixtureIDs = []
        super.tearDown()
    }

    func testPlacedCountIncludesGivensAndPlayerValues() {
        // A given 5 at index 0 plus a player-placed 5 at index 9.
        let game = makeGame(givens: [0: 5], playerValues: [9: 5])
        XCTAssertEqual(game.placedCount(of: 5), 2)
        XCTAssertEqual(game.placedCount(of: 3), 0)
        XCTAssertFalse(game.isExhausted(5))
    }

    func testDigitBecomesExhaustedOnNinthPlacement() {
        let game = makeGame(playerValues: eightFives())
        XCTAssertFalse(game.isExhausted(5))

        game.selectCell(at: 40)
        game.inputNumber(5)

        XCTAssertEqual(game.placedCount(of: 5), 9)
        XCTAssertTrue(game.isExhausted(5))
    }

    func testUndoRevivesExhaustedDigit() {
        let game = makeGame(playerValues: eightFives())
        game.selectCell(at: 40)
        game.inputNumber(5)
        XCTAssertTrue(game.isExhausted(5))

        game.undoLastMove()
        XCTAssertFalse(game.isExhausted(5), "Undo must revive the numpad key")

        game.redoLastMove()
        XCTAssertTrue(game.isExhausted(5), "Redo must exhaust it again")
    }

    func testClearingCellRevivesExhaustedDigit() {
        let game = makeGame(playerValues: eightFives())
        game.selectCell(at: 40)
        game.inputNumber(5)
        XCTAssertTrue(game.isExhausted(5))

        game.clearSelectedCell()
        XCTAssertFalse(game.isExhausted(5), "Clearing a cell must revive the numpad key")
    }

    // MARK: - Fixtures

    /// Eight player-placed 5s spread over the board, leaving index 40 free.
    private func eightFives() -> [Int: Int] {
        Dictionary(uniqueKeysWithValues: [0, 10, 20, 30, 41, 50, 60, 70].map { ($0, 5) })
    }

    private func makeGame(givens: [Int: Int] = [:], playerValues: [Int: Int] = [:]) -> SudokuGame {
        var initial = Array(repeating: 0, count: 81)
        for (index, value) in givens { initial[index] = value }
        var player = Array(repeating: 0, count: 81)
        for (index, value) in playerValues { player[index] = value }
        let solution = (0..<81).map { index -> Int in
            let row = index / 9
            let col = index % 9
            return (row * 3 + row / 3 + col) % 9 + 1
        }

        let record = GameRecord(
            id: UUID(),
            startTime: Date(),
            lastPlayedTime: Date(),
            difficulty: "EASY",
            difficultyIndex: 10,
            initialBoard: initial,
            solution: solution,
            playerBoard: player,
            playerNotes: Array(repeating: [], count: 81),
            isSolved: false,
            ratingChange: nil
        )
        fixtureIDs.append(record.id)

        let game = SudokuGame()
        game.loadFromRecord(record)
        return game
    }
}
