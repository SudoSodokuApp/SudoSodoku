import XCTest
@testable import SudoSodoku

final class SudokuGeneratorTests: XCTestCase {

    // MARK: - Solved board

    func testGeneratedSolvedBoardIsCompleteAndValid() {
        let board = SudokuGenerator.generateSolvedBoard()

        XCTAssertEqual(board.count, 81)
        XCTAssertFalse(board.contains(0), "Solved board must have no empty cells")
        assertBoardSatisfiesSudokuRules(board)
    }

    // MARK: - Puzzle generation

    func testGeneratedPuzzlesAreSolvableUniqueAndScored() {
        for difficulty in Difficulty.allCases {
            let (puzzle, solution, score) = SudokuGenerator.generatePuzzle(targetDifficulty: difficulty)

            XCTAssertEqual(puzzle.count, 81, "\(difficulty.rawValue): puzzle must have 81 cells")
            XCTAssertEqual(solution.count, 81, "\(difficulty.rawValue): solution must have 81 cells")
            assertBoardSatisfiesSudokuRules(solution)

            for index in 0..<81 where puzzle[index] != 0 {
                XCTAssertEqual(
                    puzzle[index], solution[index],
                    "\(difficulty.rawValue): given at \(index) must match the solution"
                )
            }

            let clueCount = puzzle.filter { $0 != 0 }.count
            XCTAssertGreaterThanOrEqual(
                clueCount, 17,
                "\(difficulty.rawValue): a proper puzzle needs at least 17 clues"
            )

            XCTAssertEqual(
                SudokuGenerator.countSolutions(board: puzzle, limit: 2), 1,
                "\(difficulty.rawValue): puzzle must have exactly one solution"
            )

            XCTAssertTrue((0...100).contains(score), "\(difficulty.rawValue): score must be normalized to 0-100")
        }
    }

    // MARK: - Difficulty scoring

    func testNormalizeClampsToValidRange() {
        XCTAssertEqual(SudokuGenerator.normalize(Int(SudokuGenerator.MIN_RAW_SCORE)), 0)
        XCTAssertEqual(SudokuGenerator.normalize(Int(SudokuGenerator.MAX_RAW_SCORE)), 100)
        XCTAssertEqual(SudokuGenerator.normalize(0), 0, "Raw scores below MIN must clamp to 0")
        XCTAssertEqual(SudokuGenerator.normalize(999), 100, "Raw scores above MAX must clamp to 100")
    }

    func testDifficultyScoreRangesCoverFullScaleWithoutOverlap() {
        let ranges = Difficulty.allCases.map { $0.scoreRange }
        var covered = Set<Int>()

        for range in ranges {
            for value in range {
                XCTAssertFalse(covered.contains(value), "Score \(value) belongs to more than one difficulty")
                covered.insert(value)
            }
        }
        XCTAssertEqual(covered, Set(0...100), "Difficulty ranges must exactly cover 0-100")
    }

    // MARK: - Validity checks

    func testIsValidRejectsRowColumnAndBoxConflicts() {
        var board = Array(repeating: 0, count: 81)
        board[0] = 5 // row 0, col 0

        XCTAssertFalse(SudokuGenerator.isValid(board, 5, 0, 8), "Same row conflict must be rejected")
        XCTAssertFalse(SudokuGenerator.isValid(board, 5, 8, 0), "Same column conflict must be rejected")
        XCTAssertFalse(SudokuGenerator.isValid(board, 5, 1, 1), "Same box conflict must be rejected")
        XCTAssertTrue(SudokuGenerator.isValid(board, 5, 4, 4), "Unrelated cell must accept the value")
        XCTAssertTrue(SudokuGenerator.isValid(board, 3, 0, 1), "Different value in same row must be accepted")
    }

    // MARK: - Helpers

    private func assertBoardSatisfiesSudokuRules(_ board: [Int], file: StaticString = #filePath, line: UInt = #line) {
        let expected = Set(1...9)

        for unit in 0..<9 {
            let row = Set((0..<9).map { board[unit * 9 + $0] })
            XCTAssertEqual(row, expected, "Row \(unit) is not a 1-9 permutation", file: file, line: line)

            let column = Set((0..<9).map { board[$0 * 9 + unit] })
            XCTAssertEqual(column, expected, "Column \(unit) is not a 1-9 permutation", file: file, line: line)

            let startRow = (unit / 3) * 3
            let startCol = (unit % 3) * 3
            let box = Set((0..<9).map { board[(startRow + $0 / 3) * 9 + startCol + $0 % 3] })
            XCTAssertEqual(box, expected, "Box \(unit) is not a 1-9 permutation", file: file, line: line)
        }
    }
}
