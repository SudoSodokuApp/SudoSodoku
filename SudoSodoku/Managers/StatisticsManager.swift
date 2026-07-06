import Foundation
import Combine

class StatisticsManager: ObservableObject {
    static let shared = StatisticsManager()

    @Published var personalBests: [Difficulty: GameRecord] = [:]
    @Published var overallStats: OverallStats = OverallStats(
        totalGames: 0,
        solvedGames: 0,
        totalUndos: 0,
        bestLogicalEfficiency: 0
    )

    private var cancellables = Set<AnyCancellable>()

    init() {
        refreshData()
        StorageManager.shared.$records
            .sink { [weak self] _ in self?.refreshData() }
            .store(in: &cancellables)
    }

    func refreshData() {
        personalBests = getAllDifficultyBests()
        overallStats = getOverallStats()
    }

    func getPersonalBests(for difficulty: Difficulty, limit: Int = 10) -> [GameRecord] {
        StorageManager.shared.records
            .filter { $0.difficulty == difficulty.rawValue && $0.isSolved }
            .sorted { $0.logicalEfficiency > $1.logicalEfficiency }
            .prefix(limit)
            .map { $0 }
    }

    func getBestLogicalEfficiency(for difficulty: Difficulty) -> GameRecord? {
        StorageManager.shared.records
            .filter { $0.difficulty == difficulty.rawValue && $0.isSolved }
            .max { $0.logicalEfficiency < $1.logicalEfficiency }
    }

    func getAllDifficultyBests() -> [Difficulty: GameRecord] {
        var bests: [Difficulty: GameRecord] = [:]
        for difficulty in Difficulty.allCases {
            if let best = getPersonalBests(for: difficulty, limit: 1).first {
                bests[difficulty] = best
            }
        }
        return bests
    }

    func getOverallStats() -> OverallStats {
        let records = StorageManager.shared.records
        let solvedRecords = records.filter(\.isSolved)
        return OverallStats(
            totalGames: records.count,
            solvedGames: solvedRecords.count,
            totalUndos: solvedRecords.reduce(0) { $0 + $1.undoCount },
            bestLogicalEfficiency: solvedRecords.max { $0.logicalEfficiency < $1.logicalEfficiency }?.logicalEfficiency ?? 0
        )
    }

    func getDifficultyDistribution() -> [Difficulty: Int] {
        var distribution: [Difficulty: Int] = [:]
        for difficulty in Difficulty.allCases {
            distribution[difficulty] = StorageManager.shared.records
                .filter { $0.difficulty == difficulty.rawValue && $0.isSolved }
                .count
        }
        return distribution
    }

    func getRecentCompletions(limit: Int = 20) -> [GameRecord] {
        StorageManager.shared.records
            .filter(\.isSolved)
            .sorted { $0.lastPlayedTime > $1.lastPlayedTime }
            .prefix(limit)
            .map { $0 }
    }
}
