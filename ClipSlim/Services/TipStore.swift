import Foundation
import StoreKit

@MainActor
@Observable
final class TipStore {

    enum PurchaseState: Equatable {
        case idle
        case purchasing
        case success
        case failed(String)
    }

    private(set) var tips: [Product] = []
    private(set) var purchaseState: PurchaseState = .idle
    private(set) var isLoading = false

    private static let productIDs: [String] = [
        "com.appyaccidents.clipslim.tip.small",
        "com.appyaccidents.clipslim.tip.medium",
        "com.appyaccidents.clipslim.tip.large"
    ]

    func loadProducts() async {
        isLoading = true
        do {
            let products = try await Product.products(for: Self.productIDs)
            tips = products.sorted { $0.price < $1.price }
        } catch {
            Logger.shared.error("Failed to load tip products: \(error.localizedDescription)")
        }
        isLoading = false
    }

    func purchase(_ product: Product) async {
        purchaseState = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    purchaseState = .success
                    scheduleStateReset()
                case .unverified(_, let error):
                    purchaseState = .failed(error.localizedDescription)
                }
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .idle
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    private func scheduleStateReset() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            if purchaseState == .success {
                purchaseState = .idle
            }
        }
    }
}
