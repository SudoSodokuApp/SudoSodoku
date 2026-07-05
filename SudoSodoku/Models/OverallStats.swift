import Foundation

struct OverallStats {
    let totalGames: Int
    let solvedGames: Int
    let totalUndos: Int
    let bestLogicalEfficiency: Int

    var winRate: Double {
        guard totalGames > 0 else { return 0 }
        return Double(solvedGames) / Double(totalGames)
    }

    var averageUndosPerGame: Double {
        guard solvedGames > 0 else { return 0 }
        return Double(totalUndos) / Double(solvedGames)
    }
}
