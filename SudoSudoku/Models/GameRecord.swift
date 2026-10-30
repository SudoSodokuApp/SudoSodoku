import Foundation

struct GameRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let startTime: Date
    var lastPlayedTime: Date
    let difficulty: String
    let difficultyIndex: Int
    let initialBoard: [Int]
    let solution: [Int]
    var playerBoard: [Int]
    var playerNotes: [[Int]]?
    var isSolved: Bool
    var ratingChange: Int?
    
    var isArchived: Bool = false
    var isFavorite: Bool = false

    // Inert save data: tracked but never displayed or judged — undo count
    // is not a quality metric (#62, #77).
    var undoCount: Int = 0

    // Accumulated active play time in seconds (excludes backgrounded time)
    var playDuration: TimeInterval = 0

    enum CodingKeys: String, CodingKey {
        case id, startTime, lastPlayedTime, difficulty, difficultyIndex
        case initialBoard, solution, playerBoard, playerNotes
        case isSolved, ratingChange, isArchived, isFavorite, undoCount, playDuration
    }

    var progress: Int {
        if isSolved { return 100 }
        let totalToFill = initialBoard.filter { $0 == 0 }.count
        if totalToFill == 0 { return 100 }
        var filledCount = 0
        for i in 0..<81 {
            if initialBoard[i] == 0 && playerBoard[i] != 0 {
                filledCount += 1
            }
        }
        return Int((Double(filledCount) / Double(totalToFill)) * 100)
    }

    /// A fresh attempt at the same puzzle, under a new identity. The new id
    /// is the point: a solved record is immutable history (SOLVED counts,
    /// personal bests, recent completions all derive from it), so a restart
    /// must never let its autosaves overwrite the original in storage.
    func restartedCopy() -> GameRecord {
        GameRecord(
            id: UUID(),
            startTime: Date(),
            lastPlayedTime: Date(),
            difficulty: difficulty,
            difficultyIndex: difficultyIndex,
            initialBoard: initialBoard,
            solution: solution,
            playerBoard: Array(repeating: 0, count: 81),
            playerNotes: Array(repeating: [], count: 81),
            isSolved: false,
            ratingChange: nil,
            isArchived: isArchived,
            isFavorite: isFavorite,
            undoCount: 0,
            playDuration: 0
        )
    }
}

extension GameRecord {
    // Custom decoding: synthesized Codable would throw on saves written before a
    // field existed, silently discarding the whole archive. Fields added after
    // 1.0 must decode with a default instead.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        startTime = try container.decode(Date.self, forKey: .startTime)
        lastPlayedTime = try container.decode(Date.self, forKey: .lastPlayedTime)
        difficulty = try container.decode(String.self, forKey: .difficulty)
        difficultyIndex = try container.decode(Int.self, forKey: .difficultyIndex)
        initialBoard = try container.decode([Int].self, forKey: .initialBoard)
        solution = try container.decode([Int].self, forKey: .solution)
        playerBoard = try container.decode([Int].self, forKey: .playerBoard)
        playerNotes = try container.decodeIfPresent([[Int]].self, forKey: .playerNotes)
        isSolved = try container.decode(Bool.self, forKey: .isSolved)
        ratingChange = try container.decodeIfPresent(Int.self, forKey: .ratingChange)
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        undoCount = try container.decodeIfPresent(Int.self, forKey: .undoCount) ?? 0
        playDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .playDuration) ?? 0
    }
}

