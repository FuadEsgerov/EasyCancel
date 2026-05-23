import Foundation
import Observation

/// App-wide auth + onboarding state. Injected once at the app root via
/// `.environment(authStore)` and read with
/// `@Environment(AuthStore.self) private var auth`.
@MainActor
@Observable
final class AuthStore {
    enum Phase: Equatable {
        case loading    // restoring a persisted session
        case onboarding // welcome → country → sign in
        case signedIn
    }

    private(set) var phase: Phase = .loading
    private(set) var session: AuthSession?
    var errorMessage: String?
    private(set) var magicLinkSentTo: String?

    /// Domain users forward subscription emails to (spec §F3.1).
    static let forwardingDomain = "inbox.easycancel.app"

    /// The user's unique inbound address, e.g. `guest-1a2b@inbox.easycancel.app`.
    /// Nil until the session reports a local handle.
    var forwardingAddress: String? {
        session?.forwardingAddressLocal.map { "\($0)@\(Self.forwardingDomain)" }
    }

    /// Chosen during onboarding; drives legal framework + default language.
    /// Persisted so a returning user keeps their selection.
    var selectedCountry: Country {
        didSet { defaults.set(selectedCountry.code, forKey: Keys.countryCode) }
    }

    private let service: any AuthService
    private let defaults: UserDefaults

    private enum Keys {
        static let countryCode = "onboarding.countryCode"
    }

    init(service: any AuthService, defaults: UserDefaults = .standard) {
        self.service = service
        self.defaults = defaults
        if let code = defaults.string(forKey: Keys.countryCode) {
            self.selectedCountry = Country.country(for: code)
        } else {
            self.selectedCountry = Country.detected()
        }
    }

    /// Called once on launch. Skips onboarding if a session already exists.
    func restore() async {
        if let session = await service.currentSession() {
            self.session = session
            phase = .signedIn
        } else {
            phase = .onboarding
        }
    }

    func continueAsGuest() async {
        await signIn { try await service.signInAnonymously() }
    }

    func signInWithApple(idToken: String, nonce: String) async {
        await signIn { try await service.signInWithApple(idToken: idToken, nonce: nonce) }
    }

    func sendMagicLink(to email: String) async {
        errorMessage = nil
        do {
            try await service.sendMagicLink(to: email)
            magicLinkSentTo = email
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Handle the magic-link / OAuth callback URL opened into the app.
    func handleCallback(_ url: URL) async {
        do {
            if let session = try await service.completeSignIn(from: url) {
                self.session = session
                magicLinkSentTo = nil
                phase = .signedIn
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        do {
            try await service.signOut()
            session = nil
            magicLinkSentTo = nil
            phase = .onboarding
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func signIn(_ operation: () async throws -> AuthSession) async {
        errorMessage = nil
        do {
            let session = try await operation()
            self.session = session
            phase = .signedIn
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
