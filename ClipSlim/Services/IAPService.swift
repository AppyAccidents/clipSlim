import Foundation
import StoreKit

@MainActor
@Observable
final class IAPService {
    struct ProductCatalog {
        static let coffee = "com.appyaccidents.clipslim.tip.coffee"
        static let doubleCoffee = "com.appyaccidents.clipslim.tip.doublecoffee"
        static let legendaryCoffee = "com.appyaccidents.clipslim.tip.legendary"

        static let allIDs: [String] = [coffee, doubleCoffee, legendaryCoffee]
    }

    private(set) var products: [Product] = []
    private(set) var isLoading = false
    private(set) var statusMessage: String = ""
    private(set) var didThankUser = false

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: ProductCatalog.allIDs)
                .sorted(by: { $0.displayPrice < $1.displayPrice })

            if products.isEmpty {
                #if DEBUG
                statusMessage = "IAP not available in this environment."
                #else
                statusMessage = "No support products available right now."
                #endif
            } else {
                statusMessage = ""
            }
        } catch {
            products = []
            #if DEBUG
            statusMessage = "IAP not available in this environment."
            #else
            statusMessage = "Could not load support products."
            #endif
        }
    }

    func buy(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                didThankUser = true
                statusMessage = "Thank you for supporting ClipSlim."
                Logger.shared.app("IAP purchase success")
            case .pending:
                statusMessage = "Purchase is pending approval."
                Logger.shared.app("IAP purchase pending")
            case .userCancelled:
                statusMessage = "Purchase cancelled."
                Logger.shared.app("IAP purchase cancelled")
            @unknown default:
                statusMessage = "Purchase could not be completed."
                Logger.shared.app("IAP purchase unknown state")
            }
        } catch {
            statusMessage = "Purchase failed. Please try again."
            Logger.shared.error("IAP purchase failed", category: "app")
        }
    }

    func refresh() async {
        await loadProducts()
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let signedType):
            return signedType
        }
    }

    enum StoreError: Error {
        case failedVerification
    }
}
