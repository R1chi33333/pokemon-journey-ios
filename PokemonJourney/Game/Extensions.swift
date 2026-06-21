import UIKit

// MARK: - Haptics

func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
    UIImpactFeedbackGenerator(style: style).impactOccurred()
}

func hapticNotify(_ type: UINotificationFeedbackGenerator.FeedbackType = .success) {
    UINotificationFeedbackGenerator().notificationOccurred(type)
}

extension UIColor {
    convenience init(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if h.hasPrefix("#") { h = String(h.dropFirst()) }
        guard h.count == 6, let value = UInt64(h, radix: 16) else {
            self.init(white: 0.5, alpha: 1); return
        }
        self.init(
            red:   CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8)  & 0xFF) / 255,
            blue:  CGFloat( value        & 0xFF) / 255,
            alpha: 1
        )
    }
}
