import SwiftUI

enum RankTier: CaseIterable {
    case scriptKiddie
    case user
    case sudoer
    case sysAdmin
    case kernelHacker
    case architect

    var rangeLabel: String {
        switch self {
        case .scriptKiddie: return "0-1199"
        case .user: return "1200-1399"
        case .sudoer: return "1400-1599"
        case .sysAdmin: return "1600-1799"
        case .kernelHacker: return "1800-1999"
        case .architect: return "2000+"
        }
    }

    var title: String {
        switch self {
        case .scriptKiddie: return "SCRIPT_KIDDIE"
        case .user: return "USER"
        case .sudoer: return "SUDOER"
        case .sysAdmin: return "SYS_ADMIN"
        case .kernelHacker: return "KERNEL_HACKER"
        case .architect: return "THE_ARCHITECT"
        }
    }

    var color: Color {
        switch self {
        case .scriptKiddie: return .gray
        case .user: return .green
        case .sudoer: return .cyan
        case .sysAdmin: return .blue
        case .kernelHacker: return .purple
        case .architect: return .orange
        }
    }

    static func tier(for rating: Int) -> RankTier {
        switch rating {
        case ..<1200: return .scriptKiddie
        case 1200..<1400: return .user
        case 1400..<1600: return .sudoer
        case 1600..<1800: return .sysAdmin
        case 1800..<2000: return .kernelHacker
        default: return .architect
        }
    }
}
