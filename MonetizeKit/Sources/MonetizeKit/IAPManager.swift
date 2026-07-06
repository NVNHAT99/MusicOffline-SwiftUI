import Foundation
import StoreKit

/// Main facade for In-App Purchase operations using StoreKit 2
/// 
/// IAPManager provides a simplified interface for common IAP operations:
/// - Product fetching and caching
/// - Purchase flow management
/// - Transaction observation
/// - Entitlement tracking
/// - Purchase restoration
///
/// ## Usage Example
/// ```swift
/// let iap = IAPManager.shared
/// await iap.configure(productIds: ["com.app.monthly", "com.app.yearly"])
/// 
/// // Fetch products
/// let products = try await iap.products()
/// 
/// // Make a purchase
/// if let monthlyProduct = products.first(where: { $0.id == "com.app.monthly" }) {
///     let transaction = try await iap.purchase(monthlyProduct)
///     await iap.finishTransaction(transaction)
/// }
/// 
/// // Observe entitlements
/// for await entitlements in iap.entitlementsStream {
///     // Update UI based on current entitlements
/// }
/// ```
public actor IAPManager {
    
    /// Shared singleton instance
    public static let shared = IAPManager()
    
    private let productStore: ProductStoreProtocol
    private let purchases: PurchasesProtocol
    private var configuredProductIds: [String] = []
    private var isConfigured = false
    
    /// Initialize with custom dependencies (useful for testing)
    /// - Parameters:
    ///   - productStore: Custom product store implementation
    ///   - purchases: Custom purchases implementation
    public init(
        productStore: ProductStoreProtocol = ProductStore(),
        purchases: PurchasesProtocol? = nil
    ) {
        self.productStore = productStore
        self.purchases = purchases ?? Purchases()
    }
    
    // MARK: - Configuration
    
    /// Configure the IAP manager with product identifiers
    /// 
    /// This method should be called early in your app's lifecycle, typically in
    /// `application(_:didFinishLaunchingWithOptions:)` or `App.init()`.
    ///
    /// - Parameter productIds: Array of product identifiers to manage
    /// - Throws: IAPError if configuration fails
    public func configure(productIds: [String]) async throws {
        guard !productIds.isEmpty else {
            throw IAPError.unknownError("Product IDs cannot be empty")
        }
        
        configuredProductIds = productIds
        
        // Start observing transactions
        await purchases.startObservingTransactions()
        
        // Pre-fetch products to populate cache
        do {
            _ = try await productStore.fetchProducts(productIds: productIds)
            isConfigured = true
        } catch {
            // Log error but don't fail configuration
            // Products can be fetched later if needed
            isConfigured = true
        }
    }
    
    /// Check if the manager has been configured
    /// - Returns: True if configured, false otherwise
    public func isConfigured() async -> Bool {
        return isConfigured
    }
    
    // MARK: - Product Management
    
    /// Get all configured products
    /// 
    /// Returns cached products if available and cache is valid,
    /// otherwise fetches fresh data from the App Store.
    ///
    /// - Returns: Array of available IAP products
    /// - Throws: IAPError if fetching fails
    public func products() async throws -> [IAPProduct] {
        guard isConfigured else {
            throw IAPError.unknownError("IAPManager not configured. Call configure(productIds:) first.")
        }
        
        // Try to return cached products if cache is valid
        let cachedProducts = await productStore.getCachedProducts()
        let isCacheValid = await productStore.isCacheValid()
        if !cachedProducts.isEmpty && isCacheValid {
            return cachedProducts.filter { configuredProductIds.contains($0.id) }
        }
        
        // Fetch fresh products
        return try await productStore.fetchProducts(productIds: configuredProductIds)
    }
    
    /// Get a specific product by ID
    /// - Parameter productId: The product identifier
    /// - Returns: IAPProduct if found, nil otherwise
    public func product(id productId: String) async throws -> IAPProduct? {
        guard configuredProductIds.contains(productId) else {
            return nil
        }
        
        // Check cache first
        if let cachedProduct = await productStore.getProduct(id: productId) {
            return cachedProduct
        }
        
        // Fetch if not in cache
        do {
            return try await productStore.fetchProduct(id: productId)
        } catch {
            return nil
        }
    }
    
    /// Refresh product data from the App Store
    /// - Returns: Array of refreshed products
    /// - Throws: IAPError if refresh fails
    public func refreshProducts() async throws -> [IAPProduct] {
        guard isConfigured else {
            throw IAPError.unknownError("IAPManager not configured. Call configure(productIds:) first.")
        }
        
        await productStore.clearCache()
        return try await productStore.fetchProducts(productIds: configuredProductIds)
    }
    
    // MARK: - Purchase Operations
    
    /// Purchase a product
    /// 
    /// Initiates the purchase flow for the specified product.
    /// The transaction should be finished after successful processing.
    ///
    /// - Parameter product: The product to purchase
    /// - Returns: The completed transaction
    /// - Throws: IAPError if purchase fails
    public func purchase(_ product: IAPProduct) async throws -> TransactionProtocol {
        guard isConfigured else {
            throw IAPError.unknownError("IAPManager not configured. Call configure(productIds:) first.")
        }
        
        guard configuredProductIds.contains(product.id) else {
            throw IAPError.productNotFound("Product \(product.id) not in configured products")
        }
        
        return try await purchases.purchase(product)
    }
    
    /// Restore previous purchases
    /// 
    /// Restores all eligible purchases for the current Apple ID.
    /// Useful for non-consumable products and active subscriptions.
    ///
    /// - Returns: Array of restored transactions
    /// - Throws: IAPError if restore fails
    public func restorePurchases() async throws -> [TransactionProtocol] {
        guard isConfigured else {
            throw IAPError.unknownError("IAPManager not configured. Call configure(productIds:) first.")
        }
        
        return try await purchases.restorePurchases()
    }
    
    /// Finish a transaction
    /// 
    /// Marks a transaction as finished, removing it from the payment queue.
    /// Should be called after successful processing of the purchase.
    ///
    /// - Parameter transaction: The transaction to finish
    public func finishTransaction(_ transaction: TransactionProtocol) async {
        await purchases.finishTransaction(transaction)
    }
    
    /// Get pending transactions
    /// 
    /// Returns transactions that have been purchased but not yet finished.
    ///
    /// - Returns: Array of pending transactions
    public func pendingTransactions() async -> [TransactionProtocol] {
        return await purchases.getPendingTransactions()
    }
    
    // MARK: - Entitlement Management
    
    /// Stream of entitlement updates
    /// 
    /// Subscribe to this stream to receive real-time updates when
    /// entitlements change due to purchases, expirations, or restorations.
    ///
    /// - Returns: AsyncStream of entitlement arrays
    public var entitlementsStream: AsyncStream<[Entitlement]> {
        return purchases.entitlementsStream
    }
    
    /// Get current entitlements
    /// 
    /// Returns the current snapshot of user entitlements.
    ///
    /// - Returns: Array of current entitlements
    public func currentEntitlements() async -> [Entitlement] {
        return await purchases.getCurrentEntitlements()
    }
    
    /// Check if user has active entitlement for a product
    /// - Parameter productId: The product identifier to check
    /// - Returns: True if user has active entitlement, false otherwise
    public func hasActiveEntitlement(for productId: String) async -> Bool {
        return await purchases.hasActiveEntitlement(for: productId)
    }
    
    /// Get entitlement for a specific product
    /// - Parameter productId: The product identifier
    /// - Returns: Entitlement if found, nil otherwise
    public func entitlement(for productId: String) async -> Entitlement? {
        return await purchases.getEntitlement(for: productId)
    }

    /// Get the first active entitlement, refreshing from StoreKit if cache has none.
    /// - Returns: Active Entitlement if found, nil otherwise
    public func getActiveEntitlement() async -> Entitlement? {
        return await purchases.getActiveEntitlementWithRefresh()
    }

    /// Refresh the App Store receipt
    ///
    /// Requests a fresh receipt from the App Store.
    /// Useful when the receipt is missing, corrupted, or needs to be updated.
    ///
    /// - Throws: IAPError if refresh fails
    public func refreshReceipt() async throws {
        guard isConfigured else {
            throw IAPError.unknownError("IAPManager not configured. Call configure(productIds:) first.")
        }

        try await purchases.refreshReceipt()
    }

    // MARK: - Utility Methods
    
    /// Get configured product IDs
    /// - Returns: Array of configured product identifiers
    public func getConfiguredProductIds() async -> [String] {
        return configuredProductIds
    }
    
    /// Clear all cached data
    /// 
    /// Clears the product cache. Useful for testing or when you want
    /// to force fresh data fetching.
    public func clearCache() async {
        await productStore.clearCache()
    }
    
    /// Cleanup resources
    /// 
    /// Stops transaction observation and cleans up resources.
    /// Should be called when the manager is no longer needed.
    public func cleanup() async {
        await purchases.stopObservingTransactions()
        await productStore.clearCache()
        isConfigured = false
        configuredProductIds.removeAll()
    }
}

// MARK: - Convenience Extensions

extension IAPManager {
    
    /// Purchase a product by ID
    /// - Parameter productId: The product identifier to purchase
    /// - Returns: The completed transaction
    /// - Throws: IAPError if product not found or purchase fails
    public func purchase(productId: String) async throws -> TransactionProtocol {
        guard let product = try await product(id: productId) else {
            throw IAPError.productNotFound(productId)
        }
        return try await purchase(product)
    }
    
    /// Get products filtered by type
    /// - Parameter type: The product type to filter by
    /// - Returns: Array of products matching the specified type
    /// - Throws: IAPError if fetching fails
    public func products(ofType type: ProductType) async throws -> [IAPProduct] {
        let allProducts = try await products()
        return allProducts.filter { $0.type == type }
    }
    
    /// Get subscription products
    /// - Returns: Array of subscription products
    /// - Throws: IAPError if fetching fails
    public func subscriptionProducts() async throws -> [IAPProduct] {
        let allProducts = try await products()
        return allProducts.filter { 
            $0.type == .autoRenewableSubscription || $0.type == .nonRenewableSubscription 
        }
    }
    
    /// Get consumable products
    /// - Returns: Array of consumable products
    /// - Throws: IAPError if fetching fails
    public func consumableProducts() async throws -> [IAPProduct] {
        return try await products(ofType: .consumable)
    }
    
    /// Get non-consumable products
    /// - Returns: Array of non-consumable products
    /// - Throws: IAPError if fetching fails
    public func nonConsumableProducts() async throws -> [IAPProduct] {
        return try await products(ofType: .nonConsumable)
    }
}
