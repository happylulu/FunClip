import Foundation
import UserNotifications
import UIKit

/// Service for managing push notifications
@MainActor
class PushNotificationService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var deviceToken: String?
    
    // MARK: - Singleton
    static let shared = PushNotificationService()
    
    private override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// Request notification permissions
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            
            if granted {
                await registerForRemoteNotifications()
            }
            
            await MainActor.run {
                self.isAuthorized = granted
            }
            
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    /// Check current authorization status
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    /// Register for remote notifications
    private func registerForRemoteNotifications() async {
        await UIApplication.shared.registerForRemoteNotifications()
    }
    
    // MARK: - Device Token
    
    /// Handle device token registration
    func registerDeviceToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = token
        
        // Send token to backend
        Task {
            await sendTokenToBackend(token)
        }
    }
    
    /// Send device token to backend
    private func sendTokenToBackend(_ token: String) async {
        guard let url = URL(string: "\(AppConfig.Backend.apiURL)/devices/register") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add auth token if available
        if let authToken = try? KeychainService().retrieve(for: "backend_token") {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        let body = [
            "device_token": token,
            "platform": "ios",
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        ]
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               200..<300 ~= httpResponse.statusCode {
                print("Device token registered successfully")
            }
        } catch {
            print("Failed to register device token: \(error)")
        }
    }
    
    // MARK: - Local Notifications
    
    /// Schedule a local notification for processing completion
    func scheduleProcessingCompleteNotification(jobId: String, clipCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "🎬 Clips Ready!"
        content.body = "Your video has been processed. \(clipCount) viral clips are ready to share!"
        content.sound = .default
        content.badge = 1
        content.userInfo = ["job_id": jobId]
        
        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "processing-complete-\(jobId)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    /// Schedule a local notification for processing failure
    func scheduleProcessingFailedNotification(jobId: String, error: String) {
        let content = UNMutableNotificationContent()
        content.title = "❌ Processing Failed"
        content.body = "Failed to process your video: \(error)"
        content.sound = .default
        content.userInfo = ["job_id": jobId, "error": error]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "processing-failed-\(jobId)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    /// Clear all delivered notifications
    func clearNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    // MARK: - Handle Notification Response
    
    /// Handle notification tap
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        
        if let jobId = userInfo["job_id"] as? String {
            // Post notification to navigate to results
            NotificationCenter.default.post(
                name: .navigateToResults,
                object: nil,
                userInfo: ["job_id": jobId]
            )
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationService: UNUserNotificationCenterDelegate {
    
    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Handle notification response
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleNotificationResponse(response)
        completionHandler()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let navigateToResults = Notification.Name("navigateToResults")
}

// MARK: - App Delegate Extension

extension UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            PushNotificationService.shared.registerDeviceToken(deviceToken)
        }
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error)")
    }
}