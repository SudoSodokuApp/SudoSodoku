import SwiftUI

enum Difficulty: String, CaseIterable, Codable, Identifiable {
    case easy = "EASY"
    case medium = "MEDIUM"
    case hard = "HARD"
    case master = "MASTER"

    var id: String { rawValue }

    /// The command-line flag spelling, shared by the mode selector and the
    /// breach log so the fiction stays consistent.
    var flag: String { "--" + rawValue.lowercased() }

    var scoreRange: ClosedRange<Int> {
        switch self {
        case .easy: return 0...15
        case .medium: return 16...40
        case .hard: return 41...75
        case .master: return 76...100
        }
    }
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .yellow
        case .hard: return .orange
        case .master: return .red
        }
    }
}


