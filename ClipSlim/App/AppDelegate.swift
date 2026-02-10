import Foundation
import AppKit
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        Logger.shared.app("ClipSlim launched")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        Logger.shared.app("ClipSlim terminating")
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.content.categoryIdentifier == NotificationService.donationReminderCategoryID {
            if let url = URL(string: "https://buymeacoffee.com/appyaccidents") {
                NSWorkspace.shared.open(url)
            }
        }
        completionHandler()
    }
}
