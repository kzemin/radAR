import Foundation
import UIKit
import UserNotifications

/// Owns the device's push lifecycle: ask permission (once), register with APNs,
/// and upsert the resulting token into Supabase `device_tokens`. Breaking-news
/// pushes go to every registered token, so there's no per-user config — opting
/// in (granting permission) is the only switch. Declining leaves the rest of
/// the app fully functional.
@MainActor
final class PushService {
    static let shared = PushService()
    private init() {}

    private let baseURL = SupabaseConfig.url
    private let apiKey = SupabaseConfig.publishableKey

    /// Call on launch. Prompts the first time; afterward it silently re-registers
    /// so the token stays current (APNs tokens can rotate between launches).
    func refreshRegistration() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            if granted { UIApplication.shared.registerForRemoteNotifications() }
        case .authorized, .provisional, .ephemeral:
            UIApplication.shared.registerForRemoteNotifications()
        default:
            break
        }
    }

    /// Upsert the APNs token (merge-duplicates so re-registers don't pile up rows).
    func uploadToken(_ token: String) async {
        let url = baseURL.appendingPathComponent("rest/v1/device_tokens")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        let body: [String: String] = [
            "token": token,
            "platform": "ios",
            "updated_at": ISO8601DateFormatter().string(from: Date()),
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await URLSession.shared.data(for: request)
    }
}
