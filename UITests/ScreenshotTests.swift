import XCTest

/// Generates App Store screenshots by driving the app in `-screenshots` mode
/// (offline mock, pre-signed-in, seeded data). Not part of the regression suite —
/// run explicitly with `-only-testing:EasyCancelUITests/ScreenshotTests`.
final class ScreenshotTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    /// Captures the current screen as a keepAlways attachment so it survives in
    /// the .xcresult bundle for extraction via `xcresulttool export attachments`.
    private func capture(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testCaptureAppStoreScreenshots() {
        let app = XCUIApplication()
        app.launchArguments += ["-screenshots"]
        app.launch()

        // 01 — Home: spend header + list + cooling-off badges
        XCTAssertTrue(app.staticTexts["Active monthly spend"].waitForExistence(timeout: 20),
                      "Seeded Home should appear")
        capture("01-home")

        // 02 — Subscription detail with the cooling-off card
        var row = app.buttons["Netflix"]
        if !row.waitForExistence(timeout: 10) { row = app.cells["Netflix"] }
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Netflix row should be tappable")
        row.tap()
        XCTAssertTrue(app.staticTexts["Cooling-off window active"].waitForExistence(timeout: 10),
                      "Detail cooling-off card should appear")
        capture("02-detail")

        // 03 — Withdrawal letter preview (whole sheet fits on a 6.9" screen).
        // Section headers are uppercased in the a11y tree, so wait on the
        // navigation bar instead of the header text.
        app.buttons["Cancel now"].tap()
        XCTAssertTrue(app.navigationBars["Cancel subscription"].waitForExistence(timeout: 10),
                      "Cancellation sheet should appear")
        XCTAssertTrue(app.staticTexts["Cancel Netflix?"].waitForExistence(timeout: 5))
        capture("03-letter")

        // 04 — Settings. "Not yet" sits in the home-indicator zone and isn't
        // reliably tappable, so dismiss the sheet with a swipe-down that starts
        // on the (non-scrollable) navigation bar.
        let top = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.10))
        let bottom = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
        top.press(forDuration: 0.05, thenDragTo: bottom)
        XCTAssertTrue(app.navigationBars["Cancel subscription"].waitForNonExistence(timeout: 10),
                      "Cancel sheet should dismiss")
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["Upgrade to Pro"].waitForExistence(timeout: 10),
                      "Settings should appear")
        capture("04-settings")

        // 05 — Paywall (static stand-in under -screenshots; real paywall needs StoreKit)
        app.buttons["Upgrade to Pro"].tap()
        XCTAssertTrue(app.staticTexts["EasyCancel Pro"].waitForExistence(timeout: 10),
                      "Paywall should present")
        XCTAssertTrue(app.buttons["Subscribe"].waitForExistence(timeout: 5))
        capture("05-paywall")
    }
}
