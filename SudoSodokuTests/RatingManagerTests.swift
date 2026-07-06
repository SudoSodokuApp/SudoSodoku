import XCTest
@testable import SudoSodoku

final class RatingManagerTests: XCTestCase {

    private let rating = RatingManager.shared

    // MARK: - Basic properties

    func testRatingChangeIsNeverNegative() {
        for playerRating in stride(from: 800, through: 2800, by: 200) {
            for difficultyIndex in stride(from: 0, through: 100, by: 10) {
                let change = rating.calculateRatingChange(
                    playerRating: playerRating,
                    puzzleDifficultyIndex: difficultyIndex
                )
                XCTAssertGreaterThanOrEqual(
                    change, 0,
                    "Player \(playerRating) vs puzzle index \(difficultyIndex) must never lose rating"
                )
            }
        }
    }

    func testHarderPuzzleYieldsMoreGain() {
        let easyGain = rating.calculateRatingChange(playerRating: 1200, puzzleDifficultyIndex: 10)
        let hardGain = rating.calculateRatingChange(playerRating: 1200, puzzleDifficultyIndex: 80)
        XCTAssertGreaterThan(hardGain, easyGain, "Harder puzzles must reward more rating")
    }

    func testEqualStrengthMatchGainsRoughlyHalfK() {
        // Puzzle index 33 -> puzzle rating 800 + 33*12 = 1196, nearly equal to player 1200.
        // Expected score ~0.5, so gain should be close to K/2 = 16.
        let change = rating.calculateRatingChange(playerRating: 1200, puzzleDifficultyIndex: 33)
        XCTAssertTrue((14...18).contains(change), "Equal-strength gain was \(change), expected ~16")
    }

    // MARK: - Anti-smurfing

    func testHighRatedPlayerGainsNothingFromTrivialPuzzle() {
        // Puzzle index 0 -> puzzle rating 800; a 2500 player is 1700 points above it.
        let change = rating.calculateRatingChange(playerRating: 2500, puzzleDifficultyIndex: 0)
        XCTAssertEqual(change, 0, "Anti-smurfing: trivial puzzles must give zero rating to top players")
    }

    // MARK: - Adaptive K-factor

    func testKFactorCapsGainByTier() {
        // Maximum possible gain approaches K as the puzzle outrates the player.
        let below2000 = rating.calculateRatingChange(playerRating: 1000, puzzleDifficultyIndex: 100)
        XCTAssertLessThanOrEqual(below2000, 32)
        XCTAssertGreaterThan(below2000, 24, "A 1000 player beating a 2000-rated puzzle should gain close to K=32")

        let below2400 = rating.calculateRatingChange(playerRating: 2000, puzzleDifficultyIndex: 100)
        XCTAssertLessThanOrEqual(below2400, 24)

        let above2400 = rating.calculateRatingChange(playerRating: 2400, puzzleDifficultyIndex: 100)
        XCTAssertLessThanOrEqual(above2400, 16)
    }

    // MARK: - Rank titles

    func testRankTitleMatchesTierBoundaries() {
        XCTAssertEqual(rating.getRankTitle(rating: 1100).title, RankTier.tier(for: 1100).title)
        XCTAssertEqual(RankTier.tier(for: 1200), RankTier.tier(for: 1399), "1200-1399 must share one tier")
        XCTAssertNotEqual(RankTier.tier(for: 1199), RankTier.tier(for: 1200), "Tier boundary at 1200 must split")
    }
}
