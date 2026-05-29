import SwiftUI

@main
struct EasyCancelApp: App {
    @UIApplicationDelegateAdaptor(PushAppDelegate.self) private var appDelegate
    @State private var store = SubscriptionStore(
        service: EasyCancelApp.makeSubscriptionService(),
        cache: EasyCancelApp.makeCache()
    )
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

    /// Offline cache for the subscription list. Skipped for UI tests/screenshots
    /// so a prior run's on-disk data can't leak into a deterministic fixture.
    private static func makeCache() -> SubscriptionCache? {
        guard !isUITest && !isScreenshots else { return nil }
        return SubscriptionCache.makeDefault()
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
                            WidgetBridge.update(with: subs)
                            LiveActivityController.sync(with: subs)
                        }
                        await notifications.reschedule(for: store.activeSubscriptions)
                        // Register for server-driven push once signed in (the
                        // token upload is gated on the live backend internally).
                        if auth.phase == .signedIn { PushService.shared.register() }
                    }
                    await storeManager.start()
                }
                .onOpenURL { url in
                    Task { await auth.handleCallback(url) }
                }
        }
    }
}
