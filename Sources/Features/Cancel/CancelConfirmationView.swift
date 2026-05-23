import SwiftUI

struct CancelConfirmationView: View {
    @Environment(SubscriptionStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let subscription: Subscription

    @State private var selectedCountry = "UK"
    @State private var isSending = false

    private static let countryCodes = ["DE", "UK", "FR", "ES", "IT", "NL", "PL"]

    private var rules: CountryRules {
        CountryRules.rules(for: selectedCountry)
    }

    // Legal: pending per-market legal review. Keep this template in English
    // until each jurisdiction's withdrawal letter is professionally translated.
    private var letterPreview: String {
        let today = Date().formatted(date: .long, time: .omitted)
        return """
        To: \(subscription.merchantName)
        Date: \(today)

        Subject: Notice of Withdrawal / Cancellation of Subscription

        Dear Sir or Madam,

        I hereby exercise my right of withdrawal from the subscription contract with \(subscription.merchantName), in accordance with \(rules.legalCitation).

        I request that you cancel my subscription with immediate effect and confirm the cancellation in writing.

        Please refund any amounts charged after the cancellation date.

        Yours faithfully,
        [Your Name]
        """
    }

    var body: some View {
        NavigationStack {
            Form {
                headerSection
                impactSection
                countrySection
                letterSection
                actionsSection
            }
            .navigationTitle("Cancel subscription")
            .navigationBarTitleDisplayMode(.inline)
            .disabled(isSending)
        }
    }

    private var headerSection: some View {
        Section {
            VStack(spacing: 6) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 44))
                    .foregroundStyle(.red)
                    .accessibilityHidden(true)
                Text("Cancel \(subscription.merchantName)?")
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
    }

    private var impactSection: some View {
        Section("Impact") {
            if let renewal = subscription.nextRenewalDate {
                Label(
                    "You'll lose access on \(renewal.formatted(date: .long, time: .omitted))",
                    systemImage: "calendar.badge.minus"
                )
                .foregroundStyle(.primary)
            } else {
                Label("Access ends when cancellation is confirmed", systemImage: "calendar.badge.minus")
                    .foregroundStyle(.primary)
            }
            LabeledContent("Amount saved", value: subscription.amountFormatted + "/" + subscription.billingFrequency.shortLabel)
        }
    }

    private var countrySection: some View {
        Section("Your country") {
            Picker("Country", selection: $selectedCountry) {
                ForEach(Self.countryCodes, id: \.self) { code in
                    Text(countryName(for: code)).tag(code)
                }
            }
            LabeledContent("Legal basis", value: rules.legalCitation)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var letterSection: some View {
        Section("Withdrawal letter preview") {
            ScrollView {
                Text(letterPreview)
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            }
            .frame(maxHeight: 220)
        }
    }

    private var actionsSection: some View {
        Section {
            Button {
                isSending = true
                Task {
                    await store.cancel(subscription, method: .letterEmail)
                    isSending = false
                    dismiss()
                }
            } label: {
                HStack {
                    if isSending {
                        ProgressView()
                            .padding(.trailing, 4)
                    }
                    Text(isSending ? "Sending…" : "Send cancellation")
                        .frame(maxWidth: .infinity)
                        .font(.body.weight(.semibold))
                }
            }
            .listRowBackground(Color.red.opacity(0.12))
            .foregroundStyle(.red)

            Button(role: .cancel) {
                dismiss()
            } label: {
                Text("Not yet")
                    .frame(maxWidth: .infinity)
            }
            .foregroundStyle(.secondary)
        }
    }

    private func countryName(for code: String) -> String {
        Country.country(for: code).localizedName
    }
}

#Preview {
    let store = SubscriptionStore.previewLoaded()
    let subscription = store.subscriptions.first ?? Subscription(
        id: UUID(),
        merchantName: "Netflix",
        amountCents: 1599,
        currency: "EUR",
        billingFrequency: .monthly,
        signupDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
        nextRenewalDate: Calendar.current.date(byAdding: .day, value: 28, to: Date()),
        status: .active
    )
    return CancelConfirmationView(subscription: subscription)
        .environment(store)
}
