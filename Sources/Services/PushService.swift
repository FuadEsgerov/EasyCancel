import Foundation
import UIKit

/// Registers the device for remote (APNs) push and stores the token in Supabase
/// so the backend can send server-driven reminders (e.g. when a forwarded email
/// adds a subscription, or a renewal is imminent). On-device local reminders
/// (`NotificationService`) work independently and don't need this.
///
/// ⚠️ Delivery requires external setup that can't be done in code:
///   1. Enable the Push Notifications capability on the App ID in the Apple
///      Developer portal.
///   2. Create an APNs auth key (.p8) and add it + key id + team id as secrets
///      to the `send-push` edge function.
/// Until then, the token is still captured and stored harmlessly.
@MainActor
final class PushService {
    static let shared = PushService()
    private init() {}

    private(set) var lastToken: String?

    /// Ask iOS to register for remote notifications. Idempotent — safe to call
    /// on every launch once the user is signed in.
    func register() {
        UIApplication.shared.registerForRemoteNotifications()
    }

    /// Called by the AppDelegate when APNs returns a device token.
    func didRegister(deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        guard token != lastToken else { return }
        lastToken = token
        Task { await upload(token) }
    }

    private func upload(_ token: String) async {
        guard SupabaseConfig.useLiveBackend else { return }
        do {
            let userID = try await SupabaseClientProvider.shared.auth.session.user.id
            try await SupabaseClientProvider.shared
                .from("device_tokens")
                .upsert(DeviceTokenRow(user_id: userID.uuidString, token: token, platform: "ios"),
                        onConflict: "token")
                .execute()
        } catch {
            // Best-effort: not being able to store the token shouldn't surface
            // an error to the user; local reminders still work.
        }
    }
}

private struct DeviceTokenRow: Encodable {
    let user_id: String
    let token: String
    let platform: String
}

/// Bridges UIKit's remote-notification callbacks to `PushService`.
final class PushAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in PushService.shared.didRegister(deviceToken: deviceToken) }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Common in the simulator (no APNs) and when push isn't provisioned yet.
        // Local reminders are unaffected, so we fail silently.
    }
}
