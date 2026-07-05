import SwiftUI

struct StatsView: View {
    @ObservedObject private var stats = StatisticsManager.shared

    var body: some View {
        ZStack {
            TerminalBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    sectionHeader("SYSTEM_OVERVIEW:")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(title: "TOTAL_GAMES", value: "\(stats.overallStats.totalGames)", icon: "gamecontroller")
                        StatCard(title: "SOLVED", value: "\(stats.overallStats.solvedGames)", icon: "checkmark.seal")
                        StatCard(title: "WIN_RATE", value: winRateString, icon: "percent")
                        StatCard(title: "BEST_EFF", value: "\(stats.overallStats.bestLogicalEfficiency)", icon: "bolt")
                    }

                    sectionHeader("PERSONAL_BEST_RECORDS:")
                    VStack(spacing: 8) {
                        ForEach(Difficulty.allCases, id: \.self) { difficulty in
                            PersonalBestRow(difficulty: difficulty, record: stats.personalBests[difficulty])
                        }
                    }

                    sectionHeader("DIFFICULTY_DISTRIBUTION:")
                    difficultyDistribution

                    let recents = stats.getRecentCompletions(limit: 10)
                    if !recents.isEmpty {
                        sectionHeader("RECENT_COMPLETIONS:")
                        VStack(spacing: 8) {
                            ForEach(recents) { record in
                                recentRow(record)
                            }
                        }
                    }

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundColor(.gray)
    }

    private var difficultyDistribution: some View {
        let distribution = stats.getDifficultyDistribution()
        let maxCount = max(distribution.values.max() ?? 1, 1)
        return VStack(spacing: 10) {
            ForEach(Difficulty.allCases, id: \.self) { difficulty in
                let count = distribution[difficulty] ?? 0
                HStack(spacing: 10) {
                    Text(difficulty.rawValue)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(difficulty.color)
                        .frame(width: 56, alignment: .leading)
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.05))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(difficulty.color.opacity(0.7))
                                .frame(width: geometry.size.width * CGFloat(count) / CGFloat(maxCount))
                        }
                    }
                    .frame(height: 14)
                    Text("\(count)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 28, alignment: .trailing)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
    }

    @ViewBuilder
    private func recentRow(_ record: GameRecord) -> some View {
        HStack {
            Text(record.difficulty.uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(Difficulty(rawValue: record.difficulty)?.color ?? .gray)
                .frame(width: 56, alignment: .leading)
            Text("EFF: \(record.logicalEfficiency)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(LogicalEfficiencyStyle.color(for: record.logicalEfficiency))
            Spacer()
            Text(DateFormatting.archiveDate.string(from: record.lastPlayedTime))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }

    private var winRateString: String {
        String(format: "%.0f%%", stats.overallStats.winRate * 100)
    }
}
