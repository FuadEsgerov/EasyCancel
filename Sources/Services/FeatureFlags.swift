import Foundation

/// Compile-time feature toggles.
enum FeatureFlags {
    /// Email-forward auto-detection. Requires deployed infra (Resend inbound +
    /// the `parse-email` edge function + DNS/MX on the inbox domain). Off until
    /// that's live so v1 ships no dead UI; flip to `true` once deployed.
    static let emailForwardingEnabled = false
}
