import XCTest

/// UI smoke tests for the core happy path. Run against the offline mock
/// (`-uiTest` launch arg) so they never touch the live Supabase backend.
final class EasyCancelUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// Launches the app and walks onboarding → guest sign-in → Home.
    @discardableResult
    private func launchToHome() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTest"]
        app.launch()

        XCTAssertTrue(app.buttons["Get started"].waitForExistence(timeout: 15),
                      "Welcome screen should appear")
        app.buttons["Get started"].tap()

        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5),
                      "Country selection should appear")
        app.buttons["Continue"].tap()

        XCTAssertTrue(app.buttons["Continue as guest"].waitForExistence(timeout: 5),
                      "Sign-in screen should appear")
        app.buttons["Continue as guest"].tap()
        return app
    }

    func testGuestOnboardingReachesEmptyHome() {
        let app = launchToHome()
        XCTAssertTrue(app.staticTexts["No subscriptions yet"].waitForExistence(timeout: 15),
                      "Empty Home state should appear after guest sign-in")
    }

    func testAddSubscriptionAppearsInList() {
        let app = launchToHome()
        XCTAssertTrue(app.staticTexts["No subscriptions yet"].waitForExistence(timeout: 15))

        app.buttons["Enter manually"].firstMatch.tap()

        let name = app.textFields["Name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5), "Add form should appear")
        name.tap()
        name.typeText("Acme Box")

        let amount = app.textFields["Amount (e.g. 9.99)"]
        amount.tap()
        amount.typeText("12.50")

        app.buttons["Save"].tap()

        // Empty state is replaced by the populated list, whose spend header
        // ("Active monthly spend") only renders when a subscription exists.
        XCTAssertTrue(app.staticTexts["Active monthly spend"].waitForExistence(timeout: 10),
                      "Subscription list should appear after adding")
        XCTAssertFalse(app.staticTexts["No subscriptions yet"].exists,
                       "Empty state should be gone after adding")
    }

    func testPaywallOpensFromSettings() {
        let app = launchToHome()
        XCTAssertTrue(app.staticTexts["No subscriptions yet"].waitForExistence(timeout: 15))

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["Upgrade to Pro"].waitForExistence(timeout: 5),
                      "Settings should offer Upgrade to Pro")
        app.buttons["Upgrade to Pro"].tap()

        XCTAssertTrue(app.staticTexts["EasyCancel Pro"].waitForExistence(timeout: 10),
                      "Paywall should present")
    }

    /// A free user at the cap taps "+" → sees the limit alert → "Upgrade to Pro"
    /// opens the paywall. Uses `-screenshots` (seeded mock = 4 active subs > cap).
    func testFreeLimitAlertOpensPaywall() {
        let app = XCUIApplication()
        app.launchArguments += ["-screenshots"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Active monthly spend"].waitForExistence(timeout: 20),
                      "Seeded Home should appear")
        app.buttons["Add subscription"].tap()

        XCTAssertTrue(app.staticTexts["Free plan limit reached"].waitForExistence(timeout: 5),
                      "Limit alert should appear at the free cap")
        app.buttons["Upgrade to Pro"].tap()

        XCTAssertTrue(app.staticTexts["EasyCancel Pro"].waitForExistence(timeout: 10),
                      "Paywall should open from the limit alert")
    }
}
