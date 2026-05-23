import SwiftUI

struct SettingsView: View {
    @Environment(SubscriptionStore.self) private var store
    @Environment(AuthStore.self) private var auth
    @Environment(StoreManager.self) private var storeManager
    @State private var showingPaywall = false

    init() {}

    var body: some View {
        NavigationStack {
            Form {
                accountSection
                subscriptionSection
                privacySection
                aboutSection
                signOutSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    private var accountSection: some View {
        Section("Account") {
            LabeledContent("Email", value: auth.session?.email ?? String(localized: "Guest"))
            LabeledContent("Country", value: auth.selectedCountry.localizedName)
            LabeledContent("Legal basis", value: auth.selectedCountry.rules.legalCitation)
        }
    }

    private var signOutSection: some View {
        Section {
            Button("Sign out", role: .destructive) {
                Task { await auth.signOut() }
            }
        }
    }

    private var subscriptionSection: some View {
        Section("Subscription") {
            if storeManager.isPro {
                HStack {
                    Label("EasyCancel Pro", systemImage: "crown.fill")
                        .foregroundStyle(.primary)
                    Spacer()
                    Text("Active")
                        .foregroundStyle(.green)
                        .fontWeight(.medium)
                }
            } else {
                Button {
                    showingPaywall = true
                } label: {
                    HStack {
                        Label("Upgrade to Pro", systemImage: "crown.fill")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Button("Restore purchases") {
                Task { await storeManager.restore() }
            }
            .foregroundStyle(.primary)
        }
    }

    private var privacySection: some View {
        Section("Privacy") {
            Button("Export my data") {
            }
            .foregroundStyle(.primary)

            Button("Delete account", role: .destructive) {
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: "1.0")
        }
    }
}

#Preview {
    SettingsView()
        .environment(SubscriptionStore.previewLoaded())
        .environment(AuthStore(service: MockAuthService()))
        .environment(StoreManager())
}
