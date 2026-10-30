import XCTest
@testable import SudoSudoku

/// Conflict rules for data arriving from iCloud: two iPhones playing
/// offline must both keep their progress once they sync.
final class SaveDataMergeTests: XCTestCase {

    // MARK: - Rating ledger

    func testGainsFromTwoDevicesBothCount() {
        var phoneA = RatingLedger()
        phoneA.set(30, for: .gain("a"))
        var phoneB = RatingLedger()
        phoneB.set(25, for: .gain("b"))

        XCTAssertEqual(phoneA.merging(phoneB).rating, 1255)
        XCTAssertEqual(phoneB.merging(phoneA).rating, 1255, "Merge order must not matter")
    }

    func testTheSameSolveSyncedTwiceCountsOnce() {
        var ledger = RatingLedger()
        ledger.set(30, for: .gain("same-game"))

        XCTAssertEqual(ledger.merging(ledger).rating, 1230)
    }

    func testBaselinesMergeByMaxSoARestoredBackupDoesNotDoubleCount() {
        // Two installs migrated from copies of the same pre-sync history.
        let original = RatingLedger(baselines: ["install-1": 400])
        let restored = RatingLedger(baselines: ["install-2": 400])

        XCTAssertEqual(original.merging(restored).rating, 1600)
    }

    func testMigrationCarriesTheOldRatingOver() {
        XCTAssertEqual(RatingLedger.migrating(rating: 1777).rating, 1777)
        XCTAssertEqual(RatingLedger.migrating(rating: 1200).baselines, [:],
                       "A starting rating needs no baseline line")
    }

    func testKeysRoundTripThroughRecordNames() {
        for key in [RatingLedger.Key.baseline("x-1"), .gain("6F9619FF-8B86-D011-B42D-00C04FC964FF")] {
            XCTAssertEqual(RatingLedger.Key(recordName: key.recordName), key)
        }
        XCTAssertNil(RatingLedger.Key(recordName: "6F9619FF-8B86-D011-B42D-00C04FC964FF"),
                     "A game record name is not a rating line")
    }

    // MARK: - Game records

    func testSolvedCopyBeatsUnsolvedEitherWay() {
        let unsolved = makeRecord(isSolved: false)
        var solved = unsolved
        solved.isSolved = true

        XCTAssertTrue(SaveDataMerge.resolve(local: unsolved, remote: solved, localHasPendingChanges: true).isSolved)
        XCTAssertTrue(SaveDataMerge.resolve(local: solved, remote: unsolved, localHasPendingChanges: false).isSolved,
                      "An older unsolved copy must never roll a solve back")
    }

    func testUnsentLocalEditWinsOverServerCopy() {
        var local = makeRecord(isSolved: false)
        local.isFavorite = true
        let remote = makeRecord(id: local.id, isSolved: false)

        XCTAssertTrue(SaveDataMerge.resolve(local: local, remote: remote, localHasPendingChanges: true).isFavorite)
        XCTAssertFalse(SaveDataMerge.resolve(local: local, remote: remote, localHasPendingChanges: false).isFavorite,
                       "With nothing pending, the server copy is the newer one")
    }

    func testMergeAddsNewGamesAppliesDeletionsAndSortsNewestFirst() {
        let old = makeRecord(lastPlayed: 100)
        let doomed = makeRecord(lastPlayed: 200)
        let fromOtherPhone = makeRecord(lastPlayed: 300)

        let merged = SaveDataMerge.merge(
            local: [doomed, old],
            incoming: [fromOtherPhone],
            deleted: [doomed.id],
            pending: []
        )

        XCTAssertEqual(merged.map(\.id), [fromOtherPhone.id, old.id])
    }

    // MARK: - Achievements

    func testRemoteUnlocksMergeWithoutAnnouncingOrEchoing() {
        let suite = "SaveDataMergeTests"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }
        let manager = AchievementManager(defaults: defaults)
        var echoed = false
        manager.onUnlockSetChange = { _, _ in echoed = true }

        manager.applyRemote(unlocked: [Achievement.helloWorld.rawValue], removed: [])

        XCTAssertTrue(manager.isUnlocked(.helloWorld))
        XCTAssertFalse(echoed)
        XCTAssertEqual(manager.evaluateVictory(VictoryContext(
            difficulty: .easy, playDuration: 400, newRating: 1210, totalSolved: 1
        )), [], "An unlock synced from another phone must not announce again")
    }

    // MARK: - Fixtures

    private func makeRecord(id: UUID = UUID(), isSolved: Bool = false, lastPlayed: TimeInterval = 100) -> GameRecord {
        GameRecord(
            id: id,
            startTime: Date(timeIntervalSince1970: 0),
            lastPlayedTime: Date(timeIntervalSince1970: lastPlayed),
            difficulty: "EASY",
            difficultyIndex: 10,
            initialBoard: Array(repeating: 0, count: 81),
            solution: Array(repeating: 1, count: 81),
            playerBoard: Array(repeating: 0, count: 81),
            playerNotes: nil,
            isSolved: isSolved,
            ratingChange: nil
        )
    }
}
