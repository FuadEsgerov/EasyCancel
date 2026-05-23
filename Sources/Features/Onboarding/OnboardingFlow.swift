import SwiftUI

/// Three-step onboarding: welcome → country → sign in. Drives `AuthStore`;
/// once signed in, `RootView` swaps this out for the main tab view.
struct OnboardingFlow: View {
    @State private var step: Step = .welcome

    private enum Step { case welcome, country, signIn }

    var body: some View {
        Group {
            switch step {
            case .welcome:
                WelcomeView { advance(to: .country) }
            case .country:
                CountrySelectionView { advance(to: .signIn) }
            case .signIn:
                SignInView()
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        ))
    }

    private func advance(to step: Step) {
        withAnimation(.snappy) { self.step = step }
    }
}

#Preview {
    OnboardingFlow()
        .environment(AuthStore(service: MockAuthService()))
}
