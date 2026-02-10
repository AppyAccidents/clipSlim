import Foundation
import UserNotifications

final class NotificationService {

    static let shared = NotificationService()

    static let donationReminderCategoryID = "DONATION_REMINDER"
    static let donationReminderActionID = "OPEN_BMC"
    private static let donationReminderIntervalDays: Double = 14

    private let log = Logger.shared
    private var isAuthorized = false

    private init() {}

    func requestAuthorization() {
        let donateAction = UNNotificationAction(
            identifier: Self.donationReminderActionID,
            title: "Open Buy Me a Coffee",
            options: [.foreground]
        )
        let donationCategory = UNNotificationCategory(
            identifier: Self.donationReminderCategoryID,
            actions: [donateAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([donationCategory])

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
            self?.isAuthorized = granted
            if let error = error {
                self?.log.app("Notification authorization error: \(error.localizedDescription)", type: .error)
            } else {
                self?.log.app("Notification authorization \(granted ? "granted" : "denied")")
            }
        }
    }

    func scheduleDonationReminderIfNeeded(settings: AppSettings) {
        let lastEpoch = settings.lastDonationPromptEpoch
        let intervalSeconds = Self.donationReminderIntervalDays * 24 * 3600
        let now = Date().timeIntervalSince1970

        guard now - lastEpoch >= intervalSeconds else { return }

        UNUserNotificationCenter.current().getNotificationSettings { [weak self] notifSettings in
            guard notifSettings.authorizationStatus == .authorized else { return }

            let content = UNMutableNotificationContent()
            content.title = "Enjoying ClipSlim? ☕"
            content.body = "If ClipSlim saves you time, consider buying me a coffee!"
            content.categoryIdentifier = Self.donationReminderCategoryID
            content.sound = nil

            let request = UNNotificationRequest(
                identifier: "donation-reminder",
                content: content,
                trigger: nil
            )

            UNUserNotificationCenter.current().add(request) { [weak self] error in
                if let error = error {
                    self?.log.error("Failed to schedule donation reminder: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        settings.lastDonationPromptEpoch = Date().timeIntervalSince1970
                    }
                    self?.log.app("Donation reminder scheduled")
                }
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
