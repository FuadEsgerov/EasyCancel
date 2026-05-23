import Testing
import StoreKit
import StoreKitTest
@testable import EasyCancel

@MainActor
struct StoreKitProductTests {
    @Test func loadsConfiguredProProducts() async throws {
        let session = try SKTestSession(configurationFileNamed: "Configuration")
        session.resetToDefaultState()
        session.clearTransactions()

        let products = try await Product.products(for: ProProduct.all)
        #expect(products.count == 2)

        let monthly = products.first { $0.id == ProProduct.monthly }
        let yearly = products.first { $0.id == ProProduct.yearly }
        #expect(monthly != nil)
        #expect(yearly != nil)
        #expect(monthly?.type == .autoRenewable)
        #expect(yearly?.type == .autoRenewable)

        // Monthly carries the 7-day free trial introductory offer (spec).
        #expect(monthly?.subscription?.introductoryOffer?.paymentMode == .freeTrial)
        #expect(monthly?.subscription?.introductoryOffer?.period.unit == .week)
    }
}
