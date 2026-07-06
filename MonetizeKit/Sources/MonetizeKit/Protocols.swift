import Foundation
import StoreKit

// MARK: - Transaction Protocol
/// Protocol for transaction objects (both real StoreKit Transaction and mock implementations)
public protocol TransactionProtocol: Sendable {
    var id: UInt64 { get }
    var originalID: UInt64 { get }
    var productID: String { get }
    var purchaseDate: Date { get }
    var expirationDate: Date? { get }
    var revocationDate: Date? { get }
    var isUpgraded: Bool { get }
    
    func finish() async
}

// MARK: - Product Store Protocol
/// Protocol for managing product fetching and caching
public protocol ProductStoreProtocol: Actor {
    /// Fetch products from the App Store
    /// - Parameter productIds: Array of product identifiers to fetch
    /// - Returns: Array of IAPProduct objects
    /// - Throws: IAPError if fetching fails
    func fetchProducts(productIds: [String]) async throws -> [IAPProduct]
    
    /// Get cached products
    /// - Returns: Array of cached IAPProduct objects
    func getCachedProducts() async -> [IAPProduct]
    
    /// Get a specific product by ID
    /// - Parameter productId: The product identifier
    /// - Returns: IAPProduct if found, nil otherwise
    func getProduct(id productId: String) async -> IAPProduct?
    
    /// Clear the product cache
    func clearCache() async
    
    /// Check if the cache is still valid
    /// - Returns: True if cache is valid, false otherwise
    func isCacheValid() async -> Bool
    
    /// Fetch a single product by ID
    /// - Parameter id: The product identifier
    /// - Returns: IAPProduct if found
    /// - Throws: IAPError if fetching fails
    func fetchProduct(id: String) async throws -> IAPProduct?
}

// MARK: - Purchases Protocol
/// Protocol for managing purchase operations and transaction observation
public protocol PurchasesProtocol: Actor {
    /// Start observing transactions
    func startObservingTransactions() async
    
    /// Stop observing transactions
    func stopObservingTransactions() async
    
    /// Purchase a product
    /// - Parameter product: The IAPProduct to purchase
    /// - Returns: The transaction result
    /// - Throws: IAPError if purchase fails
    func purchase(_ product: IAPProduct) async throws -> TransactionProtocol
    
    /// Restore purchases for the current user
    /// - Returns: Array of restored transactions
    /// - Throws: IAPError if restore fails
    func restorePurchases() async throws -> [TransactionProtocol]
    
    /// Get pending transactions
    /// - Returns: Array of unfinished transactions
    func getPendingTransactions() async -> [TransactionProtocol]
    
    /// Finish a transaction
    /// - Parameter transaction: The transaction to finish
    func finishTransaction(_ transaction: TransactionProtocol) async
    
    /// Get the current entitlements stream
    nonisolated var entitlementsStream: AsyncStream<[Entitlement]> { get }
    
    /// Get current entitlements synchronously
    /// - Returns: Array of current entitlements
    func getCurrentEntitlements() async -> [Entitlement]
    
    /// Check if user has active entitlement for a specific product
    /// - Parameter productId: The product identifier
    /// - Returns: True if user has active entitlement
    func hasActiveEntitlement(for productId: String) async -> Bool
    
    /// Get entitlement for a specific product
    /// - Parameter productId: The product identifier
    /// - Returns: Entitlement if found, nil otherwise
    func getEntitlement(for productId: String) async -> Entitlement?

    /// Get the first active entitlement, refreshing from StoreKit if none found in cache.
    /// Fast path: returns cached entitlement if not expired.
    /// Slow path: rescans Transaction.currentEntitlements and returns first active result.
    func getActiveEntitlementWithRefresh() async -> Entitlement?

    /// Refresh the App Store receipt
    /// - Throws: IAPError if refresh fails
    func refreshReceipt() async throws
}

// MARK: - Verification Protocol
/// Protocol for transaction verification
public protocol VerificationProtocol {
    /// Verify a transaction
    /// - Parameter transaction: The transaction to verify
    /// - Returns: True if verification succeeds, false otherwise
    /// - Throws: IAPError if verification fails
    func verify(transaction: TransactionProtocol) async throws -> Bool
    
    /// Verify transaction data using JWS (JSON Web Signature)
    /// - Parameter jwsRepresentation: The JWS representation of the transaction
    /// - Returns: True if verification succeeds, false otherwise
    /// - Throws: IAPError if verification fails
    func verifyJWS(_ jwsRepresentation: String) async throws -> Bool
}