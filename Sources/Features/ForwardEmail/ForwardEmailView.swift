import SwiftUI

/// Shows the user's unique inbound address so they can forward subscription
/// confirmation emails to it (spec §7.2). The server-side `parse-email` Edge
/// Function then extracts the details and the subscription appears in-app.
struct ForwardEmailView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var didCopy = false

    private var address: String? { auth.forwardingAddress }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    addressCard
                    steps
                    privacyNote
                }
                .padding()
            }
            .navigationTitle("Forward an email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "envelope.arrow.triangle.branch")
                .font(.largeTitle)
                .foregroundStyle(.tint)
            Text("Forward a confirmation email and we'll add the subscription for you — usually within 30 seconds.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var addressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your forwarding address")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if let address {
                Text(address)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 12) {
                    Button {
                        copy(address)
                    } label: {
                        Label(didCopy ? "Copied" : "Copy address",
                              systemImage: didCopy ? "checkmark" : "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        openMail()
                    } label: {
                        Label("Open Mail", systemImage: "envelope")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                Text("Your address will appear here once you're signed in.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How it works")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            stepRow(1, "Open the confirmation email from the merchant.")
            stepRow(2, "Forward it to your address above.")
            stepRow(3, "We extract the merchant, amount and dates automatically.")
            stepRow(4, "Review and confirm — then track your cooling-off deadline.")
        }
    }

    private func stepRow(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.accentColor, in: Circle())
            Text(text)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var privacyNote: some View {
        Label("Your raw email is deleted within 7 days of processing.",
              systemImage: "lock.shield")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }

    private func copy(_ address: String) {
        UIPasteboard.general.string = address
        withAnimation { didCopy = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { didCopy = false }
        }
    }

    private func openMail() {
        guard let url = URL(string: "message://"), UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    ForwardEmailView()
        .environment(AuthStore(service: MockAuthService()))
}
