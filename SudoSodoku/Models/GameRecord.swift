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

    // Logical quality metrics
    var undoCount: Int = 0                  // Number of undos

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
    
    // Calculate logical efficiency score (based on undo count)
    var logicalEfficiency: Int {
        let baseScore = 1000
        let undoPenalty = undoCount * 10        // 10 points deducted per undo
        
        return max(0, baseScore - undoPenalty)
    }
    
    // Logical quality level
    var logicalQuality: String {
        switch logicalEfficiency {
        case 950...: return "PERFECT"
        case 850..<950: return "EXCELLENT"
        case 700..<850: return "GOOD"
        case 500..<700: return "FAIR"
        default: return "NEEDS_IMPROVEMENT"
        }
    }

    func restartedCopy() -> GameRecord {
        var restarted = self
        restarted.lastPlayedTime = Date()
        restarted.playerBoard = Array(repeating: 0, count: 81)
        restarted.playerNotes = Array(repeating: [], count: 81)
        restarted.isSolved = false
        restarted.ratingChange = nil
        restarted.undoCount = 0
        restarted.playDuration = 0
        return restarted
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

