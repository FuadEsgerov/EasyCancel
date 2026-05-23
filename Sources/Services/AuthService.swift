import Foundation

/// A signed-in user session. `email` is nil for anonymous (guest) sessions.
/// `forwardingAddressLocal` is the local part of the user's unique inbound
/// address (`profiles.forwarding_address_local`); nil until known.
struct AuthSession: Sendable, Equatable {
    let userID: UUID
    let email: String?
    let isAnonymous: Bool
    var forwardingAddressLocal: String? = nil
}

/// Abstraction over authentication (Supabase Auth in production). The app talks
/// only to this protocol; swap `MockAuthService` for `SupabaseAuthService` via
/// `SupabaseConfig.useLiveBackend`.
protocol AuthService: Sendable {
    /// Existing persisted session, if any (called on launch to skip onboarding).
    func currentSession() async -> AuthSession?
    /// Anonymous "continue as guest" session.
    func signInAnonymously() async throws -> AuthSession
    /// Send a magic-link / OTP email. Completing it requires opening the link.
    func sendMagicLink(to email: String) async throws
    /// Exchange an Apple identity token for a session.
    func signInWithApple(idToken: String, nonce: String) async throws -> AuthSession
    /// Complete a magic-link / OAuth sign-in from the callback URL the app opened.
    /// Returns nil if the URL isn't an auth callback.
    func completeSignIn(from url: URL) async throws -> AuthSession?
    func signOut() async throws
    /// GDPR account deletion: removes the user's data and signs out.
    func deleteAccount() async throws
}

/// In-memory mock. No network — guest and Apple paths sign in instantly so the
/// app is fully usable offline against the mock backend.
actor MockAuthService: AuthService {
    private var session: AuthSession?

    func currentSession() async -> AuthSession? { session }

    func signInAnonymously() async throws -> AuthSession {
        let id = UUID()
        let session = AuthSession(
            userID: id, email: nil, isAnonymous: true,
            forwardingAddressLocal: Self.handle(prefix: "guest", id: id)
        )
        self.session = session
        return session
    }

    func sendMagicLink(to email: String) async throws {
        // No real email in the mock; the user falls back to "continue as guest".
    }

    func signInWithApple(idToken: String, nonce: String) async throws -> AuthSession {
        let id = UUID()
        let session = AuthSession(
            userID: id, email: nil, isAnonymous: false,
            forwardingAddressLocal: Self.handle(prefix: "you", id: id)
        )
        self.session = session
        return session
    }

    func completeSignIn(from url: URL) async throws -> AuthSession? {
        // No deep-link flow in the mock.
        nil
    }

    func signOut() async throws {
        session = nil
    }

    func deleteAccount() async throws {
        session = nil
    }

    /// Mirrors the DB trigger's shape (`{local}-{uuid-prefix}`) for offline parity.
    private static func handle(prefix: String, id: UUID) -> String {
        "\(prefix)-\(id.uuidString.prefix(4).lowercased())"
    }
}
