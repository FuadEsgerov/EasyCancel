import XCTest

/// Drives the app through the "Beat 2" marketing flow (home → cooling-off
/// countdown → withdrawal letter) with deliberate pauses, so a simulator screen
/// recording reads smoothly on video. Not part of the regression suite.
///
/// Record while running only this test:
///   xcrun simctl io <udid> recordVideo --codec h264 out.mov   # in another shell
///   xcodebuild test-without-building -project EasyCancel.xcodeproj -scheme EasyCancel \
///     -destination 'id=<udid>' \
///     -only-testing:EasyCancelUITests/DemoRecordingTests/testRecordDemoFlow
final class DemoRecordingTests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    private func pause(_ seconds: TimeInterval) { Thread.sleep(forTimeInterval: seconds) }

    func testRecordDemoFlow() {
        let app = XCUIApplication()
        app.launchArguments += ["-screenshots"]
        app.launch()

        // Beat 2a — Home: monthly spend + subscription list + cooling-off badges
        XCTAssertTrue(app.staticTexts["Active monthly spend"].waitForExistence(timeout: 20),
                      "Seeded Home should appear")
        pause(3.0)

        // Beat 2b — Subscription detail with the cooling-off countdown card
        var row = app.buttons["Netflix"]
        if !row.waitForExistence(timeout: 10) { row = app.cells["Netflix"] }
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Netflix row should be tappable")
        row.tap()
        XCTAssertTrue(app.staticTexts["Cooling-off window active"].waitForExistence(timeout: 10),
                      "Detail cooling-off card should appear")
        pause(3.0)

        // Beat 2c — Cancellation / withdrawal-letter sheet (the differentiator)
        app.buttons["Cancel now"].tap()
        XCTAssertTrue(app.navigationBars["Cancel subscription"].waitForExistence(timeout: 10),
                      "Cancellation sheet should appear")
        XCTAssertTrue(app.staticTexts["Cancel Netflix?"].waitForExistence(timeout: 5))
        pause(3.0)

        // Gentle, controlled scroll to reveal the letter body, then settle
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.72))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.42))
        start.press(forDuration: 0.15, thenDragTo: end)
        pause(3.0)
    }
}
