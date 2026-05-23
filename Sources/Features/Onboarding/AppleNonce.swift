import Foundation
import CryptoKit

/// Nonce generation for Sign in with Apple. A random nonce is sent (SHA-256
/// hashed) in the authorization request and the raw value is passed to Supabase
/// to bind the identity token to this request, preventing replay attacks.
enum AppleNonce {
    static func random(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var bytes = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
            guard status == errSecSuccess else {
                fatalError("Unable to generate secure nonce (OSStatus \(status))")
            }
            for byte in bytes where remaining > 0 {
                if Int(byte) < charset.count {
                    result.append(charset[Int(byte)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
