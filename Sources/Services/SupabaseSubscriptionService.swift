import Foundation
import Supabase

enum SupabaseClientProvider {
    static let shared = SupabaseClient(
        supabaseURL: SupabaseConfig.url,
        supabaseKey: SupabaseConfig.publishableKey
    )
}

/// Live `SubscriptionService` backed by Supabase Postgres (PostgREST).
/// Reads/writes are RLS-protected, so an authenticated session is required for
/// `add`/`cancel`; `fetch*` return only the signed-in user's rows.
struct SupabaseSubscriptionService: SubscriptionService {
    let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientProvider.shared) {
        self.client = client
    }

    func fetchSubscriptions() async throws -> [Subscription] {
        let rows: [SubscriptionRow] = try await client
            .from("user_subscriptions")
            .select("id,custom_merchant_name,amount_cents,currency,billing_frequency,signup_date,next_renewal_date,status")
            .execute()
            .value
        return rows.compactMap(\.domain)
    }

    func fetchAttempts() async throws -> [CancellationAttempt] {
        let rows: [AttemptRow] = try await client
            .from("cancellation_attempts")
            .select("id,subscription_id,merchant_name,method,sent_at,outcome,legal_clause_cited")
            .order("sent_at", ascending: false)
            .execute()
            .value
        return rows.compactMap(\.domain)
    }

    func add(_ subscription: Subscription) async throws {
        let userID = try await currentUserID()
        let payload = SubscriptionInsert(
            user_id: userID.uuidString,
            custom_merchant_name: subscription.merchantName,
            amount_cents: subscription.amountCents,
            currency: subscription.currency,
            billing_frequency: SubscriptionRow.dbFrequency(subscription.billingFrequency),
            signup_date: Self.dateOnlyString(subscription.signupDate),
            status: subscription.status.rawValue,
            source: "manual"
        )
        try await client.from("user_subscriptions").insert(payload).execute()
    }

    func cancel(subscriptionID: UUID, method: CancellationAttempt.Method) async throws -> CancellationAttempt {
        let userID = try await currentUserID()

        let existing: [SubscriptionRow] = try await client
            .from("user_subscriptions")
            .select("id,custom_merchant_name,amount_cents,currency,billing_frequency,signup_date,next_renewal_date,status")
            .eq("id", value: subscriptionID.uuidString)
            .limit(1)
            .execute()
            .value
        let merchantName = existing.first?.custom_merchant_name ?? "Unknown"

        try await client
            .from("user_subscriptions")
            .update(["status": "cancelled"])
            .eq("id", value: subscriptionID.uuidString)
            .execute()

        let citation = CountryRules.rules(for: "UK").legalCitation
        let payload = AttemptInsert(
            subscription_id: subscriptionID.uuidString,
            user_id: userID.uuidString,
            method: AttemptRow.dbMethod(method),
            legal_clause_cited: citation,
            merchant_name: merchantName,
            outcome: "pending"
        )
        try await client.from("cancellation_attempts").insert(payload).execute()

        return CancellationAttempt(
            subscriptionID: subscriptionID,
            merchantName: merchantName,
            method: method,
            legalClauseCited: citation
        )
    }

    private func currentUserID() async throws -> UUID {
        do {
            return try await client.auth.session.user.id
        } catch {
            throw SupabaseServiceError.notAuthenticated
        }
    }

    static func dateOnlyString(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

enum SupabaseServiceError: LocalizedError {
    case notAuthenticated
    var errorDescription: String? {
        switch self {
        case .notAuthenticated: "You must be signed in to do that."
        }
    }
}

// MARK: - Row mapping

private struct SubscriptionRow: Decodable {
    let id: UUID
    let custom_merchant_name: String?
    let amount_cents: Int
    let currency: String
    let billing_frequency: String
    let signup_date: String
    let next_renewal_date: String?
    let status: String

    var domain: Subscription? {
        guard let frequency = Self.frequency(from: billing_frequency),
              let signup = Self.parseDate(signup_date) else { return nil }
        return Subscription(
            id: id,
            merchantName: custom_merchant_name ?? "Unknown",
            amountCents: amount_cents,
            currency: currency,
            billingFrequency: frequency,
            signupDate: signup,
            nextRenewalDate: next_renewal_date.flatMap(Self.parseDate),
            status: Subscription.Status(rawValue: status) ?? .active
        )
    }

    static func frequency(from raw: String) -> Subscription.BillingFrequency? {
        switch raw {
        case "weekly": .weekly
        case "monthly": .monthly
        case "quarterly": .quarterly
        case "yearly": .yearly
        case "one_time": .oneTime
        default: nil
        }
    }

    static func dbFrequency(_ frequency: Subscription.BillingFrequency) -> String {
        switch frequency {
        case .weekly: "weekly"
        case .monthly: "monthly"
        case .quarterly: "quarterly"
        case .yearly: "yearly"
        case .oneTime: "one_time"
        }
    }

    static func parseDate(_ string: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: string)
    }
}

private struct AttemptRow: Decodable {
    let id: UUID
    let subscription_id: UUID
    let merchant_name: String?
    let method: String
    let sent_at: String
    let outcome: String?
    let legal_clause_cited: String

    var domain: CancellationAttempt? {
        guard let method = Self.method(from: method) else { return nil }
        return CancellationAttempt(
            id: id,
            subscriptionID: subscription_id,
            merchantName: merchant_name ?? "Unknown",
            method: method,
            sentAt: Self.parseTimestamp(sent_at) ?? Date(),
            outcome: Self.outcome(from: outcome),
            legalClauseCited: legal_clause_cited
        )
    }

    static func method(from raw: String) -> CancellationAttempt.Method? {
        switch raw {
        case "button": .button
        case "letter_email": .letterEmail
        case "letter_certified": .letterCertified
        default: nil
        }
    }

    static func dbMethod(_ method: CancellationAttempt.Method) -> String {
        switch method {
        case .button: "button"
        case .letterEmail: "letter_email"
        case .letterCertified: "letter_certified"
        }
    }

    static func outcome(from raw: String?) -> CancellationAttempt.Outcome {
        switch raw {
        case "success": .success
        case "rejected": .rejected
        case "no_response": .noResponse
        case "disputed": .disputed
        default: .pending
        }
    }

    static func parseTimestamp(_ string: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: string) { return date }
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: string)
    }
}

private struct SubscriptionInsert: Encodable {
    let user_id: String
    let custom_merchant_name: String
    let amount_cents: Int
    let currency: String
    let billing_frequency: String
    let signup_date: String
    let status: String
    let source: String
}

private struct AttemptInsert: Encodable {
    let subscription_id: String
    let user_id: String
    let method: String
    let legal_clause_cited: String
    let merchant_name: String
    let outcome: String
}
