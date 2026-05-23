import SwiftUI

struct RootView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(SubscriptionStore.self) private var store

    var body: some View {
        Group {
            switch auth.phase {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .onboarding:
                OnboardingFlow()
            case .signedIn:
                MainTabView()
                    .task { await store.load() }
            }
        }
        .task { await auth.restore() }
    }
}

private struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "list.bullet") }
            VaultView()
                .tabItem { Label("Vault", systemImage: "lock.doc") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

#Preview {
    RootView()
        .environment(SubscriptionStore.previewLoaded())
        .environment(AuthStore(service: MockAuthService()))
        .environment(StoreManager())
}
