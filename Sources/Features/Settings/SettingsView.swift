import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(SubscriptionStore.self) private var store
    @Environment(AuthStore.self) private var auth
    @Environment(StoreManager.self) private var storeManager
    @Environment(NotificationService.self) private var notifications
    @State private var showingPaywall = false
    @State private var exportFile: ExportFile?
    @State private var showingDeleteConfirm = false

    init() {}

    var body: some View {
        NavigationStack {
            Form {
                accountSection
                subscriptionSection
                remindersSection
                privacySection
                aboutSection
                signOutSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(item: $exportFile) { file in
                ShareSheet(items: [file.url])
            }
            .confirmationDialog(
                "Delete account?",
                isPresented: $showingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete account", role: .destructive) {
                    Task { await auth.deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your account and all your data. This can't be undone.")
            }
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { auth.errorMessage != nil },
                set: { if !$0 { auth.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(auth.errorMessage ?? "")
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

    private var remindersSection: some View {
        @Bindable var notifications = notifications
        return Section("Reminders") {
            Toggle("Subscription reminders", isOn: $notifications.remindersEnabled)
                .onChange(of: notifications.remindersEnabled) { _, on in
                    if on { Task { await notifications.reschedule(for: store.activeSubscriptions) } }
                }
            Text("Get notified before each cooling-off deadline and renewal.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var privacySection: some View {
        Section("Privacy") {
            Button("Export my data") {
                exportFile = makeExport()
            }
            .foregroundStyle(.primary)

            Button("Delete account", role: .destructive) {
                showingDeleteConfirm = true
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: "1.0")
        }
    }

    /// Builds a GDPR data-export JSON file from the user's loaded data.
    private func makeExport() -> ExportFile? {
        var root: [String: Any] = [
            "exported_at": ISO8601DateFormatter().string(from: Date()),
            "account": [
                "email": auth.session?.email ?? "guest",
                "country": auth.selectedCountry.code,
            ],
        ]
        root["subscriptions"] = store.subscriptions.map { sub in
            [
                "merchant": sub.merchantName,
                "amount_cents": sub.amountCents,
                "currency": sub.currency,
                "billing_frequency": sub.billingFrequency.rawValue,
                "signup_date": ISO8601DateFormatter().string(from: sub.signupDate),
                "status": sub.status.rawValue,
            ] as [String: Any]
        }
        root["cancellations"] = store.attempts.map { attempt in
            [
                "merchant": attempt.merchantName,
                "method": attempt.method.rawValue,
                "sent_at": ISO8601DateFormatter().string(from: attempt.sentAt),
                "outcome": attempt.outcome.rawValue,
                "legal_clause": attempt.legalClauseCited,
            ] as [String: Any]
        }
        guard let data = try? JSONSerialization.data(
            withJSONObject: root, options: [.prettyPrinted, .sortedKeys]
        ) else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("easycancel-data.json")
        guard (try? data.write(to: url)) != nil else { return nil }
        return ExportFile(url: url)
    }
}

private struct ExportFile: Identifiable {
    let id = UUID()
    let url: URL
}

/// Wraps `UIActivityViewController` so SwiftUI can present the iOS share sheet.
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .environment(SubscriptionStore.previewLoaded())
        .environment(AuthStore(service: MockAuthService()))
        .environment(StoreManager())
}
