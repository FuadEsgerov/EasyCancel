import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(\.colorScheme) private var colorScheme
    @State private var email = ""
    @State private var currentNonce: String?

    var body: some View {
        // Scrollable so the screen stays usable at large Dynamic Type sizes,
        // while `minHeight` keeps the content vertically centered at normal sizes.
        GeometryReader { proxy in
            ScrollView {
                content
                    .frame(minHeight: proxy.size.height)
            }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            VStack(spacing: 8) {
                Text("Create your account")
                    .font(.title.bold())
                Text("Your data stays in the EU. Sign in to sync across devices.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer(minLength: 32)

            VStack(spacing: 16) {
                SignInWithAppleButton(.signIn) { request in
                    let nonce = AppleNonce.random()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = AppleNonce.sha256(nonce)
                } onCompletion: { result in
                    handleAppleResult(result)
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 50)

                magicLinkSection

                if let message = auth.errorMessage {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button("Continue as guest") {
                    Task { await auth.continueAsGuest() }
                }
                .font(.subheadline)
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 32)

            Text("By continuing you agree to our [Terms](https://vincli.com/docs/easyterms.pdf) and [Privacy Policy](https://vincli.com/docs/easyprivacy.pdf).")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .tint(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private var magicLinkSection: some View {
        if let sentTo = auth.magicLinkSentTo {
            Label("Sign-in link sent to \(sentTo)", systemImage: "checkmark.circle.fill")
                .font(.subheadline)
                .foregroundStyle(.green)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        } else {
            HStack {
                Rectangle().frame(height: 1).foregroundStyle(.quaternary)
                Text("or").font(.footnote).foregroundStyle(.secondary)
                Rectangle().frame(height: 1).foregroundStyle(.quaternary)
            }
            .padding(.vertical, 4)

            TextField("you@example.com", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(.fill.tertiary, in: .rect(cornerRadius: 10))

            Button {
                Task { await auth.sendMagicLink(to: email) }
            } label: {
                Text("Email me a sign-in link")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(!isValidEmail)
        }
    }

    private var isValidEmail: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        return trimmed.contains("@") && trimmed.contains(".") && trimmed.count >= 5
    }

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8),
                let nonce = currentNonce
            else {
                auth.errorMessage = String(localized: "Apple sign-in didn't return an identity token.")
                return
            }
            Task { await auth.signInWithApple(idToken: idToken, nonce: nonce) }
        case .failure(let error):
            // Ignore user cancellation; surface anything else.
            if (error as? ASAuthorizationError)?.code != .canceled {
                auth.errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    SignInView()
        .environment(AuthStore(service: MockAuthService()))
}
