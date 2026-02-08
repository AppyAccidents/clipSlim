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
        content.title = "ClipSlim"
        
        let savingsStr = String(format: "%.1f%%", result.savingsPercentage)
        let sizeStr = "\(result.formattedOriginalSize) → \(result.formattedOptimizedSize)"
        
        switch source {
        case .clipboard:
            content.body = "Clipboard optimized: \(sizeStr) (\(savingsStr) saved)"
        case .folder:
            content.body = "File optimized: \(sizeStr) (\(savingsStr) saved)"
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
        content.title = "ClipSlim Error"
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
