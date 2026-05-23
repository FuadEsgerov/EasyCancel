import Testing
import Foundation
@testable import EasyCancel

@MainActor
struct AuthStoreTests {
    private func makeStore() -> AuthStore {
        let defaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
        return AuthStore(service: MockAuthService(), defaults: defaults)
    }

    @Test func restoreWithNoSessionShowsOnboarding() async {
        let store = makeStore()
        await store.restore()
        #expect(store.phase == .onboarding)
        #expect(store.session == nil)
    }

    @Test func continueAsGuestSignsIn() async {
        let store = makeStore()
        await store.continueAsGuest()
        #expect(store.phase == .signedIn)
        #expect(store.session?.isAnonymous == true)
    }

    @Test func signOutReturnsToOnboarding() async {
        let store = makeStore()
        await store.continueAsGuest()
        await store.signOut()
        #expect(store.phase == .onboarding)
        #expect(store.session == nil)
    }

    @Test func selectedCountryPersistsAcrossInstances() {
        let defaults = UserDefaults(suiteName: "test.\(UUID().uuidString)")!
        let store = AuthStore(service: MockAuthService(), defaults: defaults)
        store.selectedCountry = Country.country(for: "DE")

        let reopened = AuthStore(service: MockAuthService(), defaults: defaults)
        #expect(reopened.selectedCountry.code == "DE")
    }
}

struct CountryDetectionTests {
    @Test func detectsGermanyFromRegion() {
        #expect(Country.detected(from: Locale(identifier: "de_DE")).code == "DE")
    }

    @Test func mapsGBRegionToUKCode() {
        #expect(Country.detected(from: Locale(identifier: "en_GB")).code == "UK")
    }

    @Test func fallsBackToUKForUnsupportedRegion() {
        #expect(Country.detected(from: Locale(identifier: "en_US")).code == "UK")
    }
}
