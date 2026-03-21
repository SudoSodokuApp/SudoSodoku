import SwiftUI

struct StatsView: View {
    @ObservedObject var stats = StatisticsManager.shared
    @ObservedObject var storage = StorageManager.shared

    var body: some View {
        ZStack {
            TerminalBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: - Overall Stats
                    sectionHeader("SYSTEM_OVERVIEW:")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(title: "TOTAL_GAMES",   value: "\(stats.overallStats.totalGames)",      icon: "gamecontroller")
                        StatCard(title: "SOLVED",        value: "\(stats.overallStats.solvedGames)",     icon: "checkmark.seal")
                        StatCard(title: "WIN_RATE",      value: winRateString,                           icon: "percent")
                        StatCard(title: "BEST_EFF",      value: "\(stats.overallStats.bestLogicalEfficiency)", icon: "bolt")
                    }

                    // MARK: - Personal Bests
                    sectionHeader("PERSONAL_BEST_RECORDS:")
                    VStack(spacing: 8) {
                        ForEach(Difficulty.allCases, id: \.self) { diff in
                            PersonalBestRow(difficulty: diff, record: stats.personalBests[diff])
                        }
                    }

                    // MARK: - Difficulty Distribution
                    sectionHeader("DIFFICULTY_DISTRIBUTION:")
                    difficultyDistribution

                    // MARK: - Recent Completions
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
        .onAppear { stats.refreshData() }
    }

    // MARK: - Subviews

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
            ForEach(Difficulty.allCases, id: \.self) { diff in
                let count = distribution[diff] ?? 0
                HStack(spacing: 10) {
                    Text(diff.rawValue)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(diff.color)
                        .frame(width: 56, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.05))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(diff.color.opacity(0.7))
                                .frame(width: geo.size.width * CGFloat(count) / CGFloat(maxCount))
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
                .foregroundColor(efficiencyColor(record.logicalEfficiency))
            Spacer()
            Text(DateFormatter.archiveDate.string(from: record.lastPlayedTime))
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }

    // MARK: - Helpers

    private var winRateString: String {
        String(format: "%.0f%%", stats.overallStats.winRate * 100)
    }

    private func efficiencyColor(_ score: Int) -> Color {
        switch score {
        case 900...: return .green
        case 700..<900: return .yellow
        case 500..<700: return .orange
        default: return .red
        }
    }
}
