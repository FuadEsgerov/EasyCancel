import Testing
import Foundation
@testable import EasyCancel

struct AddSubscriptionTests {

    // MARK: - AmountParser

    @Test func dotSeparatorParsesToCents() {
        #expect(AmountParser.cents(from: "12.99") == 1299)
    }

    @Test func commaSeparatorParsesToCents() {
        #expect(AmountParser.cents(from: "12,99") == 1299)
    }

    @Test func zeroReturnsNil() {
        #expect(AmountParser.cents(from: "0") == nil)
    }

    @Test func emptyStringReturnsNil() {
        #expect(AmountParser.cents(from: "") == nil)
    }

    @Test func nonNumericReturnsNil() {
        #expect(AmountParser.cents(from: "abc") == nil)
    }

    @Test func wholeNumberParsesToCents() {
        #expect(AmountParser.cents(from: "10") == 1000)
    }

    @Test func negativeValueReturnsNil() {
        #expect(AmountParser.cents(from: "-5.00") == nil)
    }
}
