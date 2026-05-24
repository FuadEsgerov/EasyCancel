import SwiftUI

@main
struct EasyCancelApp: App {
    @State private var store = SubscriptionStore(service: EasyCancelApp.makeSubscriptionService())
    @State private var auth = AuthStore(service: EasyCancelApp.makeAuthService())
    @State private var storeManager = StoreManager()
    @State private var notifications = NotificationService()

    /// UI tests pass `-uiTest` to force the offline mock (empty data, clean
    /// onboarding) so they never touch the live Supabase backend.
    private static var isUITest: Bool {
        ProcessInfo.processInfo.arguments.contains("-uiTest")
    }

    /// App Store screenshot generation passes `-screenshots` to force the offline
    /// mock pre-signed-in with seeded data, landing straight on a populated Home.
    private static var isScreenshots: Bool {
        ProcessInfo.processInfo.arguments.contains("-screenshots")
    }

    private static func makeSubscriptionService() -> any SubscriptionService {
        if isUITest { return MockSubscriptionService(subscriptions: []) }
        if isScreenshots { return MockSubscriptionService() }
        return SupabaseConfig.useLiveBackend ? SupabaseSubscriptionService() : MockSubscriptionService()
    }

    private static func makeAuthService() -> any AuthService {
        if isUITest { return MockAuthService() }
        if isScreenshots {
            return MockAuthService(session: AuthSession(
                userID: UUID(), email: "you@example.com", isAnonymous: false,
                forwardingAddressLocal: "you-1a2b"
            ))
        }
        return SupabaseConfig.useLiveBackend ? SupabaseAuthService() : MockAuthService()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(auth)
                .environment(storeManager)
                .environment(notifications)
                .task {
                    if !Self.isUITest && !Self.isScreenshots {
                        store.onLoaded = { subs in
                            Task { await notifications.reschedule(for: subs) }
                        }
                        await notifications.reschedule(for: store.activeSubscriptions)
                    }
                    await storeManager.start()
                }
                .onOpenURL { url in
                    Task { await auth.handleCallback(url) }
                }
        }
    }
}
