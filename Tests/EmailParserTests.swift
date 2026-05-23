import Testing
import Foundation
@testable import EasyCancel

struct EmailParserTests {

    // MARK: - Amount normalization

    @Test func parsesEUDecimalComma() {
        #expect(EmailParser.cents(fromAmount: "9,99") == 999)
    }

    @Test func parsesUSDecimalDot() {
        #expect(EmailParser.cents(fromAmount: "9.99") == 999)
    }

    @Test func parsesEUThousandsAndDecimal() {
        #expect(EmailParser.cents(fromAmount: "1.234,56") == 123456)
    }

    @Test func parsesUSThousandsAndDecimal() {
        #expect(EmailParser.cents(fromAmount: "1,234.56") == 123456)
    }

    @Test func treatsThreeTrailingDigitsAsThousands() {
        #expect(EmailParser.cents(fromAmount: "1.234") == 123400)
    }

    @Test func parsesWholeNumber() {
        #expect(EmailParser.cents(fromAmount: "15") == 1500)
    }

    @Test func zeroAmountReturnsNil() {
        #expect(EmailParser.cents(fromAmount: "0") == nil)
    }

    // MARK: - Full parse

    @Test func parsesNetflixEnglish() {
        let parsed = EmailParser.parse(
            subject: "Your Netflix membership",
            body: "Hi Jane,\nYour Netflix plan is €15,99/month starting 2026-05-20.\nThanks!",
            from: "Netflix <info@netflix.com>"
        )
        #expect(parsed.merchantName == "Netflix")
        #expect(parsed.amountCents == 1599)
        #expect(parsed.currency == "EUR")
        #expect(parsed.billingFrequency == .monthly)
        #expect(parsed.signupDate != nil)
        #expect(parsed.confidence >= 0.99)
        #expect(parsed.needsReview == false)
    }

    @Test func parsesSpotifyGBPNearKeyword() {
        let parsed = EmailParser.parse(
            subject: "Your Spotify Premium receipt",
            body: "You'll be charged £9.99 per month.",
            from: "Spotify <no-reply@spotify.com>"
        )
        #expect(parsed.merchantName == "Spotify")
        #expect(parsed.amountCents == 999)
        #expect(parsed.currency == "GBP")
        #expect(parsed.billingFrequency == .monthly)
        #expect(parsed.needsReview == false)
    }

    @Test func parsesGermanFitnessFirst() {
        let parsed = EmailParser.parse(
            subject: "Deine Mitgliedschaft bei Fitness First",
            body: "Betrag: 29,99 € monatlich. Vertragsbeginn: 20.05.2026.",
            from: "FitnessFirst <service@fitnessfirst.de>"
        )
        #expect(parsed.merchantName == "FitnessFirst")
        #expect(parsed.amountCents == 2999)
        #expect(parsed.currency == "EUR")
        #expect(parsed.billingFrequency == .monthly)
        #expect(parsed.confidence >= 0.9)
    }

    @Test func parsesYearlyUSD() {
        let parsed = EmailParser.parse(
            subject: "Your annual subscription",
            body: "Your subscription renews yearly at $75.00.",
            from: "The New York Times <subscriptions@nytimes.com>"
        )
        #expect(parsed.merchantName == "NYT")
        #expect(parsed.amountCents == 7500)
        #expect(parsed.currency == "USD")
        #expect(parsed.billingFrequency == .yearly)
    }

    @Test func derivesMerchantFromUnknownDomain() {
        let parsed = EmailParser.parse(
            subject: "Welcome to Acme Cloud",
            body: "Your plan is €4,99 per month.",
            from: "billing@acmecloud.com"
        )
        #expect(parsed.merchantName == "Acmecloud")
        #expect(parsed.amountCents == 499)
        #expect(parsed.billingFrequency == .monthly)
    }

    @Test func amountOnlyNeedsReview() {
        let parsed = EmailParser.parse(
            subject: "Receipt",
            body: "Total: €4.50",
            from: ""
        )
        #expect(parsed.merchantName == nil)
        #expect(parsed.amountCents == 450)
        #expect(parsed.currency == "EUR")
        #expect(parsed.needsReview == true)
    }

    @Test func noMatchYieldsEmptyParse() {
        let parsed = EmailParser.parse(
            subject: "Hello",
            body: "Just saying hi, nothing to see here.",
            from: ""
        )
        #expect(parsed.merchantName == nil)
        #expect(parsed.amountCents == nil)
        #expect(parsed.billingFrequency == nil)
        #expect(parsed.confidence == 0)
        #expect(parsed.hasAnything == false)
    }
}
