import SwiftUI

class RatingManager {
    static let shared = RatingManager()

    func calculateRatingChange(playerRating: Int, puzzleDifficultyIndex: Int) -> Int {
        let puzzleRating = 800.0 + (Double(puzzleDifficultyIndex) * 12.0)
        let exponent = (puzzleRating - Double(playerRating)) / 400.0
        let expectedScore = 1.0 / (1.0 + pow(10.0, exponent))
        let kFactor: Double = playerRating < 2000 ? 32.0 : (playerRating < 2400 ? 24.0 : 16.0)
        let change = kFactor * (1.0 - expectedScore)
        return max(0, Int(round(change)))
    }

    func getRankTitle(rating: Int) -> (title: String, color: Color) {
        let tier = RankTier.tier(for: rating)
        return (tier.title, tier.color)
    }
}
