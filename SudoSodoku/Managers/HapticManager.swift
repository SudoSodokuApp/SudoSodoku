import UIKit

class HapticManager {
    static let shared = HapticManager()

    func lightImpact() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
