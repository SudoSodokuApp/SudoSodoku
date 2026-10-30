import Foundation

/// The ELO rating as a mergeable ledger instead of a single number. Two
/// iPhones that each earn points offline must both keep their gains once
/// iCloud syncs them; a plain Int can only keep one side (last writer wins).
struct RatingLedger: Codable, Equatable {
    static let startingRating = 1200

    /// One ledger line, also the identity of its iCloud record.
    enum Key: Hashable {
        /// Rating carried over from before the ledger existed, one per
        /// install that migrated.
        case baseline(String)
        /// Points earned by one solve, keyed by its game record id.
        case gain(String)

        private static let baselinePrefix = "baseline."
        private static let gainPrefix = "gain."

        var recordName: String {
            switch self {
            case .baseline(let id): return Self.baselinePrefix + id
            case .gain(let id): return Self.gainPrefix + id
            }
        }

        init?(recordName: String) {
            if recordName.hasPrefix(Self.baselinePrefix) {
                self = .baseline(String(recordName.dropFirst(Self.baselinePrefix.count)))
            } else if recordName.hasPrefix(Self.gainPrefix) {
                self = .gain(String(recordName.dropFirst(Self.gainPrefix.count)))
            } else {
                return nil
            }
        }
    }

    /// Merged by max, not sum: two copies of the same pre-sync history (a
    /// phone restored from a backup of another) must not count twice.
    var baselines: [String: Int] = [:]
    /// Each solve writes its line once and never edits it, so merging is a
    /// plain union.
    var gains: [String: Int] = [:]

    var rating: Int {
        Self.startingRating + (baselines.values.max() ?? 0) + gains.values.reduce(0, +)
    }

    var keys: [Key] {
        baselines.keys.map(Key.baseline) + gains.keys.map(Key.gain)
    }

    /// Ledger for a save written before the ledger existed: its whole rating
    /// becomes one baseline under a fresh id.
    static func migrating(rating: Int) -> RatingLedger {
        let carried = rating - startingRating
        return RatingLedger(baselines: carried > 0 ? [UUID().uuidString: carried] : [:])
    }

    func points(for key: Key) -> Int? {
        switch key {
        case .baseline(let id): return baselines[id]
        case .gain(let id): return gains[id]
        }
    }

    mutating func set(_ points: Int, for key: Key) {
        switch key {
        case .baseline(let id): baselines[id] = points
        case .gain(let id): gains[id] = points
        }
    }

    mutating func remove(_ key: Key) {
        switch key {
        case .baseline(let id): baselines[id] = nil
        case .gain(let id): gains[id] = nil
        }
    }

    /// Union of both ledgers. A line present on both sides is the same
    /// immutable entry; max only guards against a corrupted copy.
    func merging(_ other: RatingLedger) -> RatingLedger {
        RatingLedger(
            baselines: baselines.merging(other.baselines, uniquingKeysWith: max),
            gains: gains.merging(other.gains, uniquingKeysWith: max)
        )
    }
}

/// Conflict rules for game records arriving from iCloud. Pure, so the sync
/// engine stays a thin translation layer and the rules stay testable.
enum SaveDataMerge {
    /// Picks the version of one game to keep.
    ///
    /// A solve always wins: solved records are immutable history, so
    /// an older unsolved copy must never roll one back. Otherwise the server
    /// copy wins unless this device still has an unsent edit of its own —
    /// then the local edit is newer than anything the server has seen.
    static func resolve(local: GameRecord?, remote: GameRecord, localHasPendingChanges: Bool) -> GameRecord {
        guard let local else { return remote }
        if local.isSolved != remote.isSolved {
            return local.isSolved ? local : remote
        }
        return localHasPendingChanges ? local : remote
    }

    /// Applies remote saves and deletions to the local record list, newest
    /// first like `StorageManager` keeps it.
    static func merge(
        local: [GameRecord],
        incoming: [GameRecord],
        deleted: Set<UUID>,
        pending: Set<UUID>
    ) -> [GameRecord] {
        var byID = Dictionary(local.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for remote in incoming {
            byID[remote.id] = resolve(
                local: byID[remote.id],
                remote: remote,
                localHasPendingChanges: pending.contains(remote.id)
            )
        }
        for id in deleted {
            byID[id] = nil
        }
        return byID.values.sorted { $0.lastPlayedTime > $1.lastPlayedTime }
    }
}
