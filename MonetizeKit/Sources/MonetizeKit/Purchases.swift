import Foundation
import StoreKit

/// Delegate for handling receipt refresh request callbacks
final class ReceiptRefreshDelegate: NSObject, SKRequestDelegate {
    let onSuccess: () -> Void
    let onError: (Error) -> Void
    var refreshRequest: SKReceiptRefreshRequest?

    init(onSuccess: @escaping () -> Void,
         onError: @escaping (Error) -> Void) {
        self.onSuccess = onSuccess
        self.onError = onError
        super.init()
    }

    func requestDidFinish(_ request: SKRequest) {
        self.refreshRequest = nil
        onSuccess()
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        self.refreshRequest = nil
        onError(error)
    }
}

/// Actor responsible for managing purchases, transaction observation, and entitlements
public actor Purchases: PurchasesProtocol {

    private var transactionUpdateTask: Task<Void, Never>?
    private var entitlements: [String: Entitlement] = [:]
    private let entitlementsContinuation: AsyncStream<[Entitlement]>.Continuation
    private let verifier: VerificationProtocol
    private var receiptRefreshDelegate: ReceiptRefreshDelegate?

    nonisolated public let entitlementsStream: AsyncStream<[Entitlement]>
    
    /// Initialize the Purchases actor
    /// - Parameter verifier: The verification protocol implementation to use
    public init(verifier: VerificationProtocol = NoOpVerifier()) {
        self.verifier = verifier
        
        let (stream, continuation) = AsyncStream.makeStream(of: [Entitlement].self)
        self.entitlementsStream = stream
        self.entitlementsContinuation = continuation
    }
    
    deinit {
        entitlementsContinuation.finish()
        transactionUpdateTask?.cancel()
    }
    
    // MARK: - PurchasesProtocol Implementation
    
    /// Start observing transactions
    public func startObservingTransactions() async {
        guard transactionUpdateTask == nil else { return }
        
        transactionUpdateTask = Task { [weak self] in
            for await verificationResult in Transaction.updates {
                await self?.handleTransactionUpdate(verificationResult)
            }
        }
        
        // Process any unfinished transactions
        await processUnfinishedTransactions()
    }
    
    /// Stop observing transactions
    public func stopObservingTransactions() async {
        transactionUpdateTask?.cancel()
        transactionUpdateTask = nil
    }
    
    /// Purchase a product
    /// - Parameter product: The IAPProduct to purchase
    /// - Returns: The transaction result
    /// - Throws: IAPError if purchase fails
    public func purchase(_ product: IAPProduct) async throws -> TransactionProtocol {
        guard let storeProduct = await getStoreProduct(for: product.id) else {
            throw IAPError.productNotFound(product.id)
        }
        
        do {
            let result = try await storeProduct.purchase()
            
            switch result {
            case .success(let verificationResult):
                let transaction = try await handlePurchaseSuccess(verificationResult)
                await updateEntitlements()
                await transaction.finish()
                return transaction
                
            case .userCancelled:
                throw IAPError.purchaseCancelled
                
            case .pending:
                throw IAPError.purchaseFailed("Purchase is pending approval")
                
            @unknown default:
                throw IAPError.unknownError("Unknown purchase result")
            }
        } catch {
            if let iapError = error as? IAPError {
                throw iapError
            }
            throw IAPError.storeKitError(error)
        }
    }
    
    /// Restore purchases for the current user
    /// - Returns: Array of restored transactions
    /// - Throws: IAPError if restore fails
    public func restorePurchases() async throws -> [TransactionProtocol] {
        var restoredTransactions: [TransactionProtocol] = []
        Transaction.currentEntitlements
        do {
            try await AppStore.sync()
            for await verificationResult in Transaction.currentEntitlements {
                if let transaction = try await processVerificationResult(verificationResult) {
                    restoredTransactions.append(transaction)
                }
            }
            
            await updateEntitlements()
            return restoredTransactions
        } catch {
            throw IAPError.storeKitError(error)
        }
    }
    
    /// Get pending transactions
    /// - Returns: Array of unfinished transactions
    public func getPendingTransactions() async -> [TransactionProtocol] {
        var pendingTransactions: [TransactionProtocol] = []
        
        for await verificationResult in Transaction.unfinished {
            if let transaction = try? await processVerificationResult(verificationResult) {
                pendingTransactions.append(transaction)
            }
        }
        
        return pendingTransactions
    }
    
    /// Finish a transaction
    /// - Parameter transaction: The transaction to finish
    public func finishTransaction(_ transaction: TransactionProtocol) async {
        await transaction.finish()
    }
    
    /// Get current entitlements synchronously
    /// - Returns: Array of current entitlements
    public func getCurrentEntitlements() async -> [Entitlement] {
        return Array(entitlements.values)
    }
    
    /// Check if user has active entitlement for a specific product
    /// - Parameter productId: The product identifier
    /// - Returns: True if user has active entitlement
    public func hasActiveEntitlement(for productId: String) async -> Bool {
        return entitlements[productId]?.isActive == true
    }
    
    /// Get entitlement for a specific product
    /// - Parameter productId: The product identifier
    /// - Returns: Entitlement if found, nil otherwise
    public func getEntitlement(for productId: String) async -> Entitlement? {
        return entitlements[productId]
    }

    /// Get first active entitlement with lazy refresh fallback.
    /// Checks in-memory cache first; rescans Transaction.currentEntitlements if none are active.
    public func getActiveEntitlementWithRefresh() async -> Entitlement? {
        // Fast path: return cached entitlement that hasn't expired yet
        if let active = entitlements.values.first(where: { !$0.isExpired }) {
            return active
        }
        // Slow path: rescan Transaction.currentEntitlements to get fresh data
        await updateEntitlements()
        return entitlements.values.first { !$0.isExpired }
    }

    /// Refresh the App Store receipt
    /// - Throws: IAPError if refresh fails
    public func refreshReceipt() async throws {
        try await withCheckedThrowingContinuation { continuation in
            // Create a delegate that holds a strong reference to itself
            let delegate = ReceiptRefreshDelegate(
                onSuccess: { [weak self] in
                    Task {
                        await self?.cleanupReceiptRefresh()
                        continuation.resume()
                    }
                },
                onError: { [weak self] error in
                    Task {
                        await self?.cleanupReceiptRefresh()
                        continuation.resume(throwing: error)
                    }
                }
            )
            // Keep strong reference to delegate t==o prevent deallocation
            self.receiptRefreshDelegate = delegate
            delegate.refreshRequest = SKReceiptRefreshRequest()
            delegate.refreshRequest?.delegate = delegate
            delegate.refreshRequest?.start()
        }
    }

    // MARK: - Private Helper Methods

    private func cleanupReceiptRefresh() async {
        receiptRefreshDelegate = nil
    }

    private func handleTransactionUpdate(_ verificationResult: VerificationResult<Transaction>) async {
        guard let transaction = try? await processVerificationResult(verificationResult) else {
            return
        }
        
        await updateEntitlements()
        
        // Auto-finish consumable transactions
        if let product = await getStoreProduct(for: transaction.productID),
           product.type == .consumable {
            await finishTransaction(transaction)
        }
    }
    
    private func handlePurchaseSuccess(_ verificationResult: VerificationResult<Transaction>) async throws -> TransactionProtocol {
        guard let transaction = try await processVerificationResult(verificationResult) else {
            throw IAPError.verificationFailed("Failed to verify purchase transaction")
        }
        
        return transaction
    }
    
    private func processVerificationResult(_ verificationResult: VerificationResult<Transaction>) async throws -> Transaction? {
        switch verificationResult {
        case .verified(let transaction):
            let isVerified = try await verifier.verify(transaction: transaction)
            if isVerified {
                return transaction
            } else {
                throw IAPError.verificationFailed("Transaction verification failed")
            }
            
        case .unverified(_, let error):
            throw IAPError.verificationFailed("Unverified transaction: \(error)")
        }
    }
    
    private func processUnfinishedTransactions() async {
        for await verificationResult in Transaction.unfinished {
            if let transaction = try? await processVerificationResult(verificationResult) {
                // Handle unfinished transaction based on product type
                if let product = await getStoreProduct(for: transaction.productID) {
                    switch product.type {
                    case .consumable:
                        // Auto-finish consumables
                        await finishTransaction(transaction)
                    case .nonConsumable, .autoRenewable, .nonRenewable:
                        // Keep non-consumables for entitlement tracking
                        await finishTransaction(transaction)
                    default:
                        break
                    }
                }
            }
        }
        
        await updateEntitlements()
    }
    
    private func updateEntitlements() async {
        var newEntitlements: [String: Entitlement] = [:]
        
        for await verificationResult in Transaction.currentEntitlements {
            guard let transaction = try? await processVerificationResult(verificationResult) else {
                continue
            }
            
            let entitlement = createEntitlement(from: transaction)
            newEntitlements[transaction.productID] = entitlement
        }
        
        entitlements = newEntitlements
        entitlementsContinuation.yield(Array(entitlements.values))
    }
    
    private func createEntitlement(from transaction: Transaction) -> Entitlement {
        let isActive: Bool
        var expirationDate: Date?
        
        // Determine if entitlement is active based on transaction state and product type
        if let expiration = transaction.expirationDate {
            expirationDate = expiration
            isActive = Date() < expiration
        } else {
            // Non-subscription products are active if not revoked
            isActive = transaction.revocationDate == nil
        }
        
        return Entitlement(
            productId: transaction.productID,
            isActive: isActive,
            purchaseDate: transaction.purchaseDate,
            expirationDate: expirationDate,
            originalTransactionId: String(transaction.originalID)
        )
    }
    
    private func getStoreProduct(for productId: String) async -> Product? {
        do {
            let products = try await Product.products(for: [productId])
            return products.first
        } catch {
            return nil
        }
    }
}
