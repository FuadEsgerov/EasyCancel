import SwiftUI

struct CountrySelectionView: View {
    let onContinue: () -> Void
    @Environment(AuthStore.self) private var auth

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Where do you live?")
                    .font(.title.bold())
                Text("This sets your consumer-rights framework and language.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)

            List {
                ForEach(Country.supported) { country in
                    Button {
                        auth.selectedCountry = country
                    } label: {
                        CountryRow(country: country, isSelected: country == auth.selectedCountry)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)

            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}

private struct CountryRow: View {
    let country: Country
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(country.flag)
                .font(.title2)
                .accessibilityHidden(true)
            Text(country.localizedName)
                .font(.body)
                .foregroundStyle(.primary)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 4)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    CountrySelectionView(onContinue: {})
        .environment(AuthStore(service: MockAuthService()))
}
