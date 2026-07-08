import Foundation

struct SudokuGenerator {
    static let MAX_RAW_SCORE = 320.0
    static let MIN_RAW_SCORE = 30.0

    /// All 27 houses: 9 rows, 9 columns, 9 boxes.
    static let allUnits: [[Int]] = {
        var units: [[Int]] = []
        for row in 0..<9 { units.append((0..<9).map { row * 9 + $0 }) }
        for col in 0..<9 { units.append((0..<9).map { $0 * 9 + col }) }
        for box in 0..<9 {
            let origin = (box / 3) * 27 + (box % 3) * 3
            units.append((0..<9).map { origin + ($0 / 3) * 9 + $0 % 3 })
        }
        return units
    }()

    /// Minimum clues that must survive digging per row/column/box, so easier
    /// boards can't end up with near-empty regions (a top-dense board with a
    /// deserted bottom half dead-ends a human even when technically solvable).
    struct ClueFloors {
        let box: Int
        let row: Int
        let column: Int
    }

    static func clueFloors(for difficulty: Difficulty) -> ClueFloors {
        switch difficulty {
        case .easy: return ClueFloors(box: 3, row: 2, column: 2)
        case .medium: return ClueFloors(box: 2, row: 1, column: 1)
        case .hard: return ClueFloors(box: 1, row: 0, column: 0)
        case .master: return ClueFloors(box: 0, row: 0, column: 0)
        }
    }

    static func generatePuzzle(targetDifficulty: Difficulty) -> ([Int], [Int], Int) {
        let solvedBoard = generateSolvedBoard()
        let floors = clueFloors(for: targetDifficulty)
        let targetCenter = Double(targetDifficulty.scoreRange.lowerBound + targetDifficulty.scoreRange.upperBound) / 2.0

        // Best-effort fallbacks, preferring boards that pass the quality gate.
        var bestQualified: (board: [Int], score: Int)?
        var bestAny: (board: [Int], score: Int)?

        func isCloser(_ score: Int, than current: (board: [Int], score: Int)?) -> Bool {
            guard let current else { return true }
            return abs(Double(score) - targetCenter) < abs(Double(current.score) - targetCenter)
        }

        let maxAttempts = 40
        for _ in 0..<maxAttempts {
            let cluesToKeep: Int
            switch targetDifficulty {
            case .easy: cluesToKeep = Int.random(in: 36...50)
            case .medium: cluesToKeep = Int.random(in: 30...40)
            case .hard: cluesToKeep = Int.random(in: 24...32)
            case .master: cluesToKeep = Int.random(in: 20...25)
            }

            let puzzle = digHoles(solvedBoard: solvedBoard, targetClues: cluesToKeep, floors: floors)
            let analysis = solveWithSingles(puzzle: puzzle)
            let normalizedScore = normalize(analysis.rawScore)

            // EASY must be finishable with singles alone and never funnel the
            // player into a single forced move (endgame excepted).
            let qualifies = targetDifficulty != .easy || (analysis.solved && analysis.minChoices >= 2)

            if qualifies && targetDifficulty.scoreRange.contains(normalizedScore) {
                return (puzzle, solvedBoard, normalizedScore)
            }
            if qualifies && isCloser(normalizedScore, than: bestQualified) {
                bestQualified = (puzzle, normalizedScore)
            }
            if isCloser(normalizedScore, than: bestAny) {
                bestAny = (puzzle, normalizedScore)
            }
        }

        let fallback = bestQualified ?? bestAny ?? (solvedBoard, 0)
        return (fallback.board, solvedBoard, fallback.score)
    }

    static func normalize(_ raw: Int) -> Int {
        let percentage = (Double(raw) - MIN_RAW_SCORE) / (MAX_RAW_SCORE - MIN_RAW_SCORE)
        let score = Int(percentage * 100)
        return max(0, min(100, score))
    }

    /// How a singles-only solver (the model of a human on EASY) experiences
    /// the puzzle: total effort, whether it ever dead-ends, and the narrowest
    /// count of simultaneously available moves. The last 8 cells are exempt
    /// from the breadth measure — the endgame is naturally forced.
    struct SinglesAnalysis {
        let rawScore: Int
        let solved: Bool
        let minChoices: Int
    }

    static func solveWithSingles(puzzle: [Int]) -> SinglesAnalysis {
        var board = puzzle
        var score = 0
        var emptyCells = board.filter { $0 == 0 }.count
        var minChoices = Int.max

        while emptyCells > 0 {
            var nakedSingles: [Int] = []
            for index in 0..<81 where board[index] == 0 {
                if getCandidates(board: board, index: index).count == 1 {
                    nakedSingles.append(index)
                }
            }

            if !nakedSingles.isEmpty {
                if emptyCells > 8 { minChoices = min(minChoices, nakedSingles.count) }
                for index in nakedSingles {
                    let candidates = getCandidates(board: board, index: index)
                    guard candidates.count == 1 else { continue }
                    board[index] = candidates[0]
                    score += 1
                    emptyCells -= 1
                }
                continue
            }

            let hidden = hiddenSingles(board: board)
            if !hidden.isEmpty {
                if emptyCells > 8 { minChoices = min(minChoices, hidden.count) }
                for (index, value) in hidden where board[index] == 0 {
                    board[index] = value
                    score += 3
                    emptyCells -= 1
                }
                continue
            }

            // Requires techniques beyond singles.
            score += emptyCells * 5
            return SinglesAnalysis(rawScore: score, solved: false, minChoices: minChoices == .max ? 0 : minChoices)
        }

        return SinglesAnalysis(rawScore: score, solved: true, minChoices: minChoices == .max ? 9 : minChoices)
    }

    static func evaluateDifficulty(puzzle: [Int]) -> Int {
        solveWithSingles(puzzle: puzzle).rawScore
    }

    static func getCandidates(board: [Int], index: Int) -> [Int] {
        var candidates: [Int] = []
        let row = index / 9
        let col = index % 9
        for num in 1...9 {
            if isValid(board, num, row, col) {
                candidates.append(num)
            }
        }
        return candidates
    }

    /// First hidden single, scanning all 27 houses. (A row-only scan here
    /// misgraded puzzles solvable via column/box logic as dead ends — the
    /// root cause of unfair "easy" boards.)
    static func findHiddenSingle(board: [Int]) -> (index: Int, value: Int)? {
        hiddenSingles(board: board).first
    }

    /// Every cell that is the only possible home for some value within one
    /// of its houses, deduplicated by cell.
    static func hiddenSingles(board: [Int]) -> [(index: Int, value: Int)] {
        var results: [(index: Int, value: Int)] = []
        var claimedCells = Set<Int>()

        for unit in allUnits {
            var counts = [Int](repeating: 0, count: 10)
            var positions = [Int](repeating: -1, count: 10)
            for index in unit where board[index] == 0 {
                for value in getCandidates(board: board, index: index) {
                    counts[value] += 1
                    positions[value] = index
                }
            }
            for value in 1...9 where counts[value] == 1 {
                let index = positions[value]
                if claimedCells.insert(index).inserted {
                    results.append((index, value))
                }
            }
        }
        return results
    }

    static func generateSolvedBoard() -> [Int] {
        var board = Array(repeating: 0, count: 81)
        _ = solve(&board)
        return board
    }

    static func solve(_ board: inout [Int]) -> Bool {
        guard let index = board.firstIndex(of: 0) else { return true }
        let numbers = (1...9).shuffled()
        for num in numbers {
            if isValid(board, num, index / 9, index % 9) {
                board[index] = num
                if solve(&board) { return true }
                board[index] = 0
            }
        }
        return false
    }

    static func isValid(_ board: [Int], _ num: Int, _ row: Int, _ col: Int) -> Bool {
        for i in 0..<9 {
            if board[row * 9 + i] == num { return false }
            if board[i * 9 + col] == num { return false }
            let r = (row / 3) * 3 + i / 3
            let c = (col / 3) * 3 + i % 3
            if board[r * 9 + c] == num { return false }
        }
        return true
    }

    static func digHoles(solvedBoard: [Int], targetClues: Int, floors: ClueFloors) -> [Int] {
        var puzzle = solvedBoard
        var rowClues = [Int](repeating: 9, count: 9)
        var colClues = [Int](repeating: 9, count: 9)
        var boxClues = [Int](repeating: 9, count: 9)
        let indices = Array(0..<81).shuffled()
        var holesToDig = 81 - targetClues

        for idx in indices {
            if holesToDig <= 0 { break }
            let row = idx / 9
            let col = idx % 9
            let box = (row / 3) * 3 + col / 3
            guard rowClues[row] > floors.row,
                  colClues[col] > floors.column,
                  boxClues[box] > floors.box else { continue }

            let backup = puzzle[idx]
            puzzle[idx] = 0
            if countSolutions(board: puzzle, limit: 2) == 1 {
                holesToDig -= 1
                rowClues[row] -= 1
                colClues[col] -= 1
                boxClues[box] -= 1
            } else {
                puzzle[idx] = backup
            }
        }
        return puzzle
    }

    static func countSolutions(board: [Int], limit: Int) -> Int {
        var copy = board
        var count = 0
        _solveCount(&copy, count: &count, limit: limit)
        return count
    }

    static func _solveCount(_ board: inout [Int], count: inout Int, limit: Int) {
        if count >= limit { return }

        // MRV: branch on the most constrained cell. Collapses the search tree
        // on sparse boards, where first-empty branching is pathologically slow.
        var bestIndex = -1
        var bestCandidates: [Int] = []
        for index in 0..<81 where board[index] == 0 {
            let candidates = getCandidates(board: board, index: index)
            if candidates.isEmpty { return } // contradiction: dead branch
            if bestIndex == -1 || candidates.count < bestCandidates.count {
                bestIndex = index
                bestCandidates = candidates
                if bestCandidates.count == 1 { break }
            }
        }
        guard bestIndex != -1 else {
            count += 1
            return
        }

        for num in bestCandidates {
            board[bestIndex] = num
            _solveCount(&board, count: &count, limit: limit)
        }
        board[bestIndex] = 0
    }
}
