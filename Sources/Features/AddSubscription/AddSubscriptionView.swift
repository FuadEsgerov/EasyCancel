import SwiftUI

// MARK: - Amount Parser

enum AmountParser {
    static func cents(from text: String, decimalSeparators: [Character] = [".", ","]) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        // Manual entry only: digits and separators. Rejects letters, negatives, currency symbols.
        guard !trimmed.isEmpty,
              trimmed.allSatisfy({ $0.isNumber || decimalSeparators.contains($0) }) else { return nil }

        // The decimal separator is the last "." or "," followed by 1–2 digits; any earlier
        // separators are thousands grouping, so "1.234,56" and "1,234.56" both parse correctly.
        let lastSep = decimalSeparators.compactMap { trimmed.lastIndex(of: $0) }.max()
        var integerPart = trimmed
        var fraction = 0
        if let sep = lastSep {
            let after = trimmed[trimmed.index(after: sep)...]
            if (1...2).contains(after.count), after.allSatisfy(\.isNumber) {
                integerPart = String(trimmed[..<sep])
                fraction = Int(after.count == 1 ? "\(after)0" : String(after)) ?? 0
            }
        }
        let digits = integerPart.filter(\.isNumber)
        guard !digits.isEmpty, let intVal = Int(digits) else { return nil }
        let cents = intVal * 100 + fraction
        return cents > 0 ? cents : nil
    }
}

// MARK: - View Model

@MainActor
@Observable
final class AddSubscriptionViewModel {
    var merchantName = ""
    var amountText = ""
    var currency = "EUR"
    var billingFrequency = Subscription.BillingFrequency.monthly
    var signupDate = Date.now

    /// Result of the most recent paste-to-autofill, used to drive the banner.
    var lastParse: ParsedSubscription?

    var isValid: Bool {
        !merchantName.trimmingCharacters(in: .whitespaces).isEmpty
            && AmountParser.cents(from: amountText) != nil
    }

    /// Fills fields from a parsed email. Only overwrites fields the parse found,
    /// so a partial parse leaves the rest for the user to complete.
    func apply(_ parsed: ParsedSubscription) {
        if let name = parsed.merchantName { merchantName = name }
        if let cents = parsed.amountCents {
            amountText = String(format: "%.2f", Double(cents) / 100)
        }
        if let currency = parsed.currency, currencies.contains(currency) {
            self.currency = currency
        }
        if let frequency = parsed.billingFrequency { billingFrequency = frequency }
        if let date = parsed.signupDate { signupDate = date }
        lastParse = parsed
    }

    let currencies = ["EUR", "GBP", "PLN", "USD"]

    func buildSubscription() -> Subscription? {
        guard let cents = AmountParser.cents(from: amountText) else { return nil }
        let name = merchantName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return nil }

        return Subscription(
            id: UUID(),
            merchantName: name,
            amountCents: cents,
            currency: currency,
            billingFrequency: billingFrequency,
            signupDate: signupDate,
            nextRenewalDate: nil,
            status: .active
        )
    }
}

// MARK: - Main View

struct AddSubscriptionView: View {
    @Environment(SubscriptionStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = AddSubscriptionViewModel()
    @State private var showingPaste = false

    var body: some View {
        NavigationStack {
            Form {
                autofillSection

                if let parse = viewModel.lastParse {
                    confidenceBanner(parse)
                }

                Section("Merchant") {
                    TextField("Name", text: $viewModel.merchantName)
                        .autocorrectionDisabled()
                }

                Section("Billing") {
                    TextField("Amount (e.g. 9.99)", text: $viewModel.amountText)
                        .keyboardType(.decimalPad)

                    Picker("Currency", selection: $viewModel.currency) {
                        ForEach(viewModel.currencies, id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }

                    Picker("Frequency", selection: $viewModel.billingFrequency) {
                        ForEach(Subscription.BillingFrequency.allCases, id: \.self) { freq in
                            Text(freq.localizedLabel).tag(freq)
                        }
                    }
                }

                Section("Dates") {
                    DatePicker(
                        "Sign-up date",
                        selection: $viewModel.signupDate,
                        in: ...Date.now,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                }
            }
            .navigationTitle("Add subscription")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!viewModel.isValid)
                }
            }
            .sheet(isPresented: $showingPaste) {
                PasteEmailSheet { parsed in
                    viewModel.apply(parsed)
                }
            }
        }
    }

    private var autofillSection: some View {
        Section {
            Button {
                showingPaste = true
            } label: {
                Label("Paste a confirmation email", systemImage: "doc.on.clipboard")
            }
        } footer: {
            Text("We'll fill in the details automatically. You can edit anything before saving.")
        }
    }

    @ViewBuilder
    private func confidenceBanner(_ parse: ParsedSubscription) -> some View {
        Section {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(parse.needsReview ? "Please double-check the details" : "Filled in from your email")
                        .font(.subheadline.weight(.semibold))
                    Text(parse.needsReview
                         ? "We weren't fully sure — confirm the amount and merchant."
                         : "Looks good. Edit anything that's off, then save.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: parse.needsReview ? "exclamationmark.triangle.fill" : "checkmark.seal.fill")
                    .foregroundStyle(parse.needsReview ? .orange : .green)
            }
        }
    }

    private func save() {
        guard let subscription = viewModel.buildSubscription() else { return }
        Task {
            await store.add(subscription)
            dismiss()
        }
    }
}

// MARK: - Paste sheet

/// Lets the user paste a raw confirmation email; on "Autofill" it runs
/// `EmailParser` and hands the result back to the form (spec F3.5).
private struct PasteEmailSheet: View {
    let onParse: (ParsedSubscription) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if text.isEmpty {
                    Text("Paste the subscription confirmation email below — subject and body are both fine.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.horizontal, .top])
                }
                TextEditor(text: $text)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal)
                    .overlay(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("Paste here…")
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 21)
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                    }
            }
            .navigationTitle("Paste email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Autofill") { autofill() }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func autofill() {
        let lines = text.components(separatedBy: .newlines)
        let subject = lines.first ?? ""
        let body = lines.dropFirst().joined(separator: "\n")
        onParse(EmailParser.parse(subject: subject, body: body))
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AddSubscriptionView()
        .environment(SubscriptionStore.previewLoaded())
}
