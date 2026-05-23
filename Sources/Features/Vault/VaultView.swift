import SwiftUI

struct VaultView: View {
    @Environment(SubscriptionStore.self) private var store

    init() {}

    var body: some View {
        NavigationStack {
            Group {
                if store.attempts.isEmpty {
                    emptyState
                } else {
                    attemptList
                }
            }
            .navigationTitle("Vault")
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No cancellations yet", systemImage: "lock.doc")
        } description: {
            Text("Your sent cancellations and legal proof will appear here.")
        }
    }

    private var attemptList: some View {
        List(store.attempts) { attempt in
            AttemptRow(attempt: attempt)
        }
        .listStyle(.insetGrouped)
    }
}

private struct AttemptRow: View {
    let attempt: CancellationAttempt

    private static let dateFormat: Date.FormatStyle = .dateTime.day().month().year()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(attempt.merchantName)
                    .font(.body)
                    .fontWeight(.semibold)
                Spacer()
                OutcomeBadge(outcome: attempt.outcome)
            }
            Text(attempt.method.label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Text(attempt.sentAt, format: Self.dateFormat)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
                Text(attempt.legalClauseCited)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct OutcomeBadge: View {
    let outcome: CancellationAttempt.Outcome

    var body: some View {
        Text(outcome.label)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(badgeColor.opacity(0.15))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
    }

    private var badgeColor: Color {
        switch outcome {
        case .pending:    return .orange
        case .success:    return .green
        case .rejected:   return .red
        case .noResponse: return .gray
        case .disputed:   return .purple
        }
    }
}

#Preview {
    VaultView()
        .environment(SubscriptionStore.previewLoaded())
}
