import SwiftUI

@main
struct EasyCancelApp: App {
    @State private var store = SubscriptionStore(service: EasyCancelApp.makeSubscriptionService())
    @State private var auth = AuthStore(service: EasyCancelApp.makeAuthService())
    @State private var storeManager = StoreManager()

    private static func makeSubscriptionService() -> any SubscriptionService {
        SupabaseConfig.useLiveBackend ? SupabaseSubscriptionService() : MockSubscriptionService()
    }

    private static func makeAuthService() -> any AuthService {
        SupabaseConfig.useLiveBackend ? SupabaseAuthService() : MockAuthService()
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
