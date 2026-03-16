import Foundation
import UserNotifications

final class NotificationService {

    static let shared = NotificationService()

    private let log = Logger.shared
    private var isAuthorized = false

    private init() {}

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
            self?.isAuthorized = granted
            if let error = error {
                self?.log.app("Notification authorization error: \(error.localizedDescription)", type: .error)
            } else {
                self?.log.app("Notification authorization \(granted ? "granted" : "denied")")
            }
        }
    }

    func sendOptimizationNotification(result: OptimizationResult, source: OptimizationEvent.Source) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "ClipSlim did a tiny heist"

        let savingsStr = String(format: "%.1f%%", result.savingsPercentage)
        let sizeStr = "\(result.formattedOriginalSize) → \(result.formattedOptimizedSize)"

        switch source {
        case .clipboard:
            content.body = "Clipboard slimmed: \(sizeStr) (\(savingsStr) rescued)"
        case .folder:
            content.body = "Folder file slimmed: \(sizeStr) (\(savingsStr) rescued)"
        case .dropZone:
            content.body = "Drop zone slimmed: \(sizeStr) (\(savingsStr) rescued)"
        }

        content.sound = nil

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error = error {
                self?.log.error("Failed to deliver notification: \(error.localizedDescription)")
            }
        }
    }

    func sendErrorNotification(message: String) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "ClipSlim hit a wall"
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
