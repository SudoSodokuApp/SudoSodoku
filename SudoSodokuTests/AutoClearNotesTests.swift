import XCTest
@testable import SudoSodoku

final class AutoClearNotesTests: XCTestCase {

    private var fixtureIDs: [UUID] = []

    override func tearDown() {
        for id in fixtureIDs {
            StorageManager.shared.deleteRecord(id: id)
        }
        fixtureIDs = []
        super.tearDown()
    }

    // MARK: - Auto-clear on placement

    func testPlacingNumberClearsItFromPeerNotes() {
        let game = makeGame(notes: [
            1: [5, 3],   // same row as cell 0
            9: [5],      // same column
            10: [5],     // same box
            80: [5],     // unrelated cell
        ])

        game.selectCell(at: 0)
        game.inputNumber(5)

        XCTAssertEqual(game.board[0].value, 5)
        XCTAssertEqual(game.board[1].notes, [3], "Peer in the same row must lose only the placed digit")
        XCTAssertTrue(game.board[9].notes.isEmpty, "Peer in the same column must lose the digit")
        XCTAssertTrue(game.board[10].notes.isEmpty, "Peer in the same box must lose the digit")
        XCTAssertEqual(game.board[80].notes, [5], "Unrelated cells must keep their notes")
    }

    func testTogglingNumberOffDoesNotTouchPeerNotes() {
        let game = makeGame(notes: [1: [5]])
        game.selectCell(at: 0)
        game.inputNumber(5)      // place
        XCTAssertTrue(game.board[1].notes.isEmpty)

        game.inputNumber(5)      // toggle off
        XCTAssertNil(game.board[0].value)
        XCTAssertTrue(game.board[1].notes.isEmpty, "Removing a value cannot resurrect peer notes")
    }

    func testNoteModeInputDoesNotClearPeerNotes() {
        let game = makeGame(notes: [1: [5]])
        game.isNoteMode = true
        game.selectCell(at: 0)
        game.inputNumber(5)

        XCTAssertEqual(game.board[0].notes, [5])
        XCTAssertEqual(game.board[1].notes, [5], "Pencil input must not clear peers")
    }

    // MARK: - Compound undo/redo

    func testUndoRestoresValueAndAllPeerNotes() {
        let game = makeGame(notes: [1: [5, 3], 9: [5], 10: [5]])
        game.selectCell(at: 0)
        game.inputNumber(5)

        game.undoLastMove()

        XCTAssertNil(game.board[0].value, "Undo must remove the placed value")
        XCTAssertEqual(game.board[1].notes, [5, 3], "Undo must restore every cleared peer note")
        XCTAssertEqual(game.board[9].notes, [5])
        XCTAssertEqual(game.board[10].notes, [5])
        XCTAssertTrue(game.undoStack.isEmpty)
        XCTAssertEqual(game.redoStack.count, 1)
    }

    func testRedoReappliesValueAndPeerNoteClearing() {
        let game = makeGame(notes: [1: [5, 3], 9: [5]])
        game.selectCell(at: 0)
        game.inputNumber(5)
        game.undoLastMove()

        game.redoLastMove()

        XCTAssertEqual(game.board[0].value, 5)
        XCTAssertEqual(game.board[1].notes, [3])
        XCTAssertTrue(game.board[9].notes.isEmpty)
        XCTAssertEqual(game.undoStack.count, 1)
        XCTAssertTrue(game.redoStack.isEmpty)
    }

    func testPlacementIntoNoteFreeBoardRecordsSingleChange() {
        let game = makeGame(notes: [:])
        game.selectCell(at: 0)
        game.inputNumber(5)

        XCTAssertEqual(game.undoStack.count, 1)
        XCTAssertEqual(game.undoStack[0].changes.count, 1, "No peer notes -> single-cell move")
    }

    // MARK: - Fixtures

    /// Board loaded from an almost-empty record so no victory can trigger.
    private func makeGame(notes: [Int: [Int]]) -> SudokuGame {
        let solution = (0..<81).map { index -> Int in
            let row = index / 9
            let col = index % 9
            return (row * 3 + row / 3 + col) % 9 + 1
        }
        var playerNotes: [[Int]] = Array(repeating: [], count: 81)
        for (index, values) in notes {
            playerNotes[index] = values
        }

        let record = GameRecord(
            id: UUID(),
            startTime: Date(),
            lastPlayedTime: Date(),
            difficulty: "EASY",
            difficultyIndex: 10,
            initialBoard: Array(repeating: 0, count: 81),
            solution: solution,
            playerBoard: Array(repeating: 0, count: 81),
            playerNotes: playerNotes,
            isSolved: false,
            ratingChange: nil
        )
        fixtureIDs.append(record.id)

        let game = SudokuGame()
        game.loadFromRecord(record)
        return game
    }
}
