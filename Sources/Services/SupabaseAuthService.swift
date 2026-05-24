import Foundation
import Supabase

/// Live `AuthService` backed by Supabase Auth. The shared client persists the
/// session to the keychain, so `currentSession()` restores it across launches.
struct SupabaseAuthService: AuthService {
    let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientProvider.shared) {
        self.client = client
    }

    func currentSession() async -> AuthSession? {
        guard let session = try? await client.auth.session else { return nil }
        return await enrich(Self.map(session))
    }

    func signInAnonymously() async throws -> AuthSession {
        let session = try await client.auth.signInAnonymously()
        return await enrich(Self.map(session))
    }

    func sendMagicLink(to email: String) async throws {
        try await client.auth.signInWithOTP(
            email: email,
            redirectTo: URL(string: "app.easycancel://login-callback")
        )
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> AuthSession {
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        return await enrich(Self.map(session))
    }

    func completeSignIn(from url: URL) async throws -> AuthSession? {
        let session = try await client.auth.session(from: url)
        return await enrich(Self.map(session))
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func deleteAccount() async throws {
        let userID = try await client.auth.session.user.id.uuidString
        // Preferred path: the `delete-account` edge function does full GDPR
        // erasure (incl. the auth.users record, which the client can't touch).
        // If it isn't deployed/reachable, fall back to deleting the user's data
        // and soft-deleting the profile so the account is still removed and the
        // user signed out. (Deploy the function to get true auth.users erasure.)
        do {
            try await client.functions.invoke("delete-account")
        } catch {
            try await client.from("notifications").delete().eq("user_id", value: userID).execute()
            try await client.from("email_parse_queue").delete().eq("user_id", value: userID).execute()
            try await client.from("cancellation_attempts").delete().eq("user_id", value: userID).execute()
            try await client.from("user_subscriptions").delete().eq("user_id", value: userID).execute()
            try await client.from("profiles")
                .update(["deleted_at": ISO8601DateFormatter().string(from: Date())])
                .eq("id", value: userID)
                .execute()
        }
        try await client.auth.signOut()
    }

    private static func map(_ session: Session) -> AuthSession {
        AuthSession(
            userID: session.user.id,
            email: session.user.email,
            isAnonymous: session.user.isAnonymous
        )
    }

    /// Fills in the user's `forwarding_address_local` from their profile row.
    /// Best-effort: the profile may not exist yet right after sign-up, in which
    /// case the session is returned unchanged.
    private func enrich(_ session: AuthSession) async -> AuthSession {
        var session = session
        let rows: [ProfileHandleRow]? = try? await client
            .from("profiles")
            .select("forwarding_address_local")
            .eq("id", value: session.userID.uuidString)
            .limit(1)
            .execute()
            .value
        session.forwardingAddressLocal = rows?.first?.forwarding_address_local
        return session
    }
}

private struct ProfileHandleRow: Decodable {
    let forwarding_address_local: String?
}
