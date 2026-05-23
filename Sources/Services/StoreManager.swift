import Foundation
import StoreKit

/// Identifiers for the EasyCancel Pro subscription. Mirrors `Configuration.storekit`
/// (and, in production, App Store Connect).
enum ProProduct {
    static let monthly = "app.easycancel.pro.monthly"
    static let yearly = "app.easycancel.pro.yearly"
    static let all = [monthly, yearly]
    static let groupID = "21500001"
}

/// Free-tier limits. Crossing these is what the paywall unlocks.
enum FreeTier {
    static let maxActiveSubscriptions = 3
}

/// Owns StoreKit 2 state: available products and the user's current entitlement.
/// Created once at app launch; the `Transaction.updates` listener starts in `init`
/// so renewals, refunds, Family Sharing and Ask-to-Buy changes are caught even
/// when no paywall is on screen.
@MainActor
@Observable
final class StoreManager {
    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    var errorMessage: String?

    var isPro: Bool { !purchasedProductIDs.isEmpty }

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = update {
                    await transaction.finish()
                    await self.refreshEntitlements()
                }
            }
        }
    }

    /// Load products and current entitlement. Call from a `.task` at app root.
    func start() async {
        await loadProducts()
        await refreshEntitlements()
    }

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: ProProduct.all)
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            errorMessage = String(localized: "Couldn't load subscription options.")
        }
    }

    /// Recompute `isPro` from the user's verified, non-revoked entitlements.
    func refreshEntitlements() async {
        var owned = Set<String>()
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.revocationDate == nil {
                owned.insert(transaction.productID)
            }
        }
        purchasedProductIDs = owned
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = String(localized: "Restore failed. Please try again.")
        }
    }
}
