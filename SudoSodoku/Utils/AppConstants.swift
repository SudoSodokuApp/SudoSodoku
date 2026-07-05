import Foundation

enum AppConstants {
    static let bundleIdentifier = "dev.kaichen.sudoku.app"
    static let leaderboardPrefix = "dev.kaichen.sudoku.app.leaderboard"

    static var marketingVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    static func leaderboardID(for difficulty: String) -> String {
        switch difficulty.lowercased() {
        case "easy":
            return "\(leaderboardPrefix).easy"
        case "medium":
            return "\(leaderboardPrefix).medium"
        case "hard":
            return "\(leaderboardPrefix).hard"
        case "master":
            return "\(leaderboardPrefix).master"
        default:
            return leaderboardPrefix
        }
    }
}
