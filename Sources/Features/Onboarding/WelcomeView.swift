import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        // Scrollable so the screen stays usable at large Dynamic Type sizes,
        // while `minHeight` keeps the content vertically centered at normal sizes.
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 24)

                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.tint)
                            .accessibilityHidden(true)
                        Text("EasyCancel")
                            .font(.largeTitle.bold())
                        Text("Exercise your legal right to cancel — in seconds, not hours.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)

                    Spacer(minLength: 32)

                    VStack(alignment: .leading, spacing: 24) {
                        ValueBullet(
                            icon: "envelope.badge",
                            title: "Track every subscription",
                            detail: "Forward a confirmation email or add it manually."
                        )
                        ValueBullet(
                            icon: "clock.badge.checkmark",
                            title: "Never miss the 14-day window",
                            detail: "We watch your cooling-off deadlines for you."
                        )
                        ValueBullet(
                            icon: "doc.text.fill",
                            title: "Cancel with legal proof",
                            detail: "One tap sends a compliant withdrawal letter."
                        )
                    }
                    .padding(.horizontal, 32)

                    Spacer(minLength: 32)

                    Button(action: onContinue) {
                        Text("Get started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .frame(minHeight: proxy.size.height)
            }
        }
    }
}

private struct ValueBullet: View {
    let icon: String
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        // Reflow icon-above-text at accessibility sizes so nothing truncates.
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 16))
        layout {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
