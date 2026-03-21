import SwiftUI

struct iPadStatsView: View {
    @ObservedObject var stats = StatisticsManager.shared

    var body: some View {
        ZStack {
            TerminalBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {

                    // MARK: - Overall Stats
                    sectionHeader("SYSTEM_OVERVIEW:")
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                        iPadStatCard(title: "TOTAL_GAMES",  value: "\(stats.overallStats.totalGames)",       icon: "gamecontroller")
                        iPadStatCard(title: "SOLVED",       value: "\(stats.overallStats.solvedGames)",      icon: "checkmark.seal")
                        iPadStatCard(title: "WIN_RATE",     value: winRateString,                            icon: "percent")
                        iPadStatCard(title: "BEST_EFF",     value: "\(stats.overallStats.bestLogicalEfficiency)", icon: "bolt")
                    }

                    // MARK: - Personal Bests + Distribution side by side
                    HStack(alignment: .top, spacing: 24) {
                        VStack(alignment: .leading, spacing: 14) {
                            sectionHeader("PERSONAL_BEST_RECORDS:")
                            ForEach(Difficulty.allCases, id: \.self) { diff in
                                PersonalBestRow(difficulty: diff, record: stats.personalBests[diff])
                            }
                        }
                        .frame(maxWidth: .infinity)

                        VStack(alignment: .leading, spacing: 14) {
                            sectionHeader("DIFFICULTY_DISTRIBUTION:")
                            difficultyDistribution
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // MARK: - Recent Completions
                    let recents = stats.getRecentCompletions(limit: 10)
                    if !recents.isEmpty {
                        sectionHeader("RECENT_COMPLETIONS:")
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(recents) { record in
                                recentRow(record)
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 40)
                .padding(.top, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { stats.refreshData() }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundColor(.gray)
    }

    private var difficultyDistribution: some View {
        let distribution = stats.getDifficultyDistribution()
        let maxCount = max(distribution.values.max() ?? 1, 1)
        return VStack(spacing: 14) {
            ForEach(Difficulty.allCases, id: \.self) { diff in
                let count = distribution[diff] ?? 0
                HStack(spacing: 12) {
                    Text(diff.rawValue)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(diff.color)
                        .frame(width: 66, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.05))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(diff.color.opacity(0.7))
                                .frame(width: geo.size.width * CGFloat(count) / CGFloat(maxCount))
                        }
                    }
                    .frame(height: 16)
                    Text("\(count)")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 32, alignment: .trailing)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }

    @ViewBuilder
    private func recentRow(_ record: GameRecord) -> some View {
        HStack {
            Text(record.difficulty.uppercased())
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(Difficulty(rawValue: record.difficulty)?.color ?? .gray)
                .frame(width: 66, alignment: .leading)
            Text("EFF: \(record.logicalEfficiency)")
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(efficiencyColor(record.logicalEfficiency))
            Spacer()
            Text(DateFormatter.archiveDate.string(from: record.lastPlayedTime))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
    }

    @ViewBuilder
    private func iPadStatCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.green)
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.all, 20)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.3), lineWidth: 1))
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
