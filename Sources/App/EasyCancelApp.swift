import SwiftUI

@main
struct EasyCancelApp: App {
    @State private var store = SubscriptionStore(service: EasyCancelApp.makeSubscriptionService())
    @State private var auth = AuthStore(service: EasyCancelApp.makeAuthService())
    @State private var storeManager = StoreManager()

    /// UI tests pass `-uiTest` to force the offline mock (empty data, clean
    /// onboarding) so they never touch the live Supabase backend.
    private static var isUITest: Bool {
        ProcessInfo.processInfo.arguments.contains("-uiTest")
    }

    private static func makeSubscriptionService() -> any SubscriptionService {
        if isUITest { return MockSubscriptionService(subscriptions: []) }
        return SupabaseConfig.useLiveBackend ? SupabaseSubscriptionService() : MockSubscriptionService()
    }

    private static func makeAuthService() -> any AuthService {
        if isUITest { return MockAuthService() }
        return SupabaseConfig.useLiveBackend ? SupabaseAuthService() : MockAuthService()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(auth)
                .environment(storeManager)
                .task { await storeManager.start() }
                .onOpenURL { url in
                    Task { await auth.handleCallback(url) }
                }
        }
    }
}
