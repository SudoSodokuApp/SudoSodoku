import SwiftUI

enum LogicalEfficiencyStyle {
    static func color(for score: Int) -> Color {
        switch score {
        case 900...: return .green
        case 700..<900: return .yellow
        case 500..<700: return .orange
        default: return .red
        }
    }
}
