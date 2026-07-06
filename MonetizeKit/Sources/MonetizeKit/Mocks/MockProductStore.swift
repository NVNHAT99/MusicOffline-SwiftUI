import Foundation
import StoreKit

/// Mock implementation of ProductStoreProtocol for testing
/// 
/// This mock allows you to simulate various product store scenarios:
/// - Successful product fetching
/// - Product not found errors
/// - Network errors
/// - Cache behavior
///
/// ## Usage Example
/// ```swift
/// let mockStore = MockProductStore()
/// mockStore.mockProducts = [
///     IAPProduct(id: "test.product", displayName: "Test Product", ...)
/// ]
/// 
/// let iapManager = IAPManager(productStore: mockStore)
/// ```
public actor MockProductStore: ProductStoreProtocol {
    
    // MARK: - Mock Configuration
    
    /// Products to return when fetchProducts is called
    public var mockProducts: [IAPProduct] = []
    
    /// Error to throw when fetchProducts is called (if set)
    public var shouldThrowError: IAPError?
    
    /// Simulated network delay in seconds
    public var simulatedDelay: TimeInterval = 0
    
    /// Whether the cache should be considered valid
    public var mockCacheValid: Bool = true
    
    /// Mock cached products (separate from mockProducts for testing cache behavior)
    public var mockCachedProducts: [IAPProduct] = []
    
    // MARK: - State Tracking
    
    private var fetchCallCount = 0
    private var clearCacheCallCount = 0
    private var lastFetchedProductIds: [String] = []
    
    public init() {}
    
    // MARK: - ProductStoreProtocol Implementation
    
    public func fetchProducts(productIds: [String]) async throws -> [IAPProduct] {
        fetchCallCount += 1
        lastFetchedProductIds = productIds
        
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }
        
        if let error = shouldThrowError {
            throw error
        }
        
        // Filter mock products to only return requested ones
        let filteredProducts = mockProducts.filter { productIds.contains($0.id) }
        
        // Check for missing products
        let foundProductIds = Set(filteredProducts.map { $0.id })
        let requestedProductIds = Set(productIds)
        let missingProductIds = requestedProductIds.subtracting(foundProductIds)
        
        if !missingProductIds.isEmpty {
            let missingIds = Array(missingProductIds).joined(separator: ", ")
            throw IAPError.productNotFound("Products not found: \(missingIds)")
        }
        
        // Update mock cache
        mockCachedProducts = filteredProducts
        
        return filteredProducts
    }
    
    public func getCachedProducts() async -> [IAPProduct] {
        return mockCachedProducts
    }
    
    public func getProduct(id productId: String) async -> IAPProduct? {
        return mockCachedProducts.first { $0.id == productId }
    }
    
    public func clearCache() async {
        clearCacheCallCount += 1
        mockCachedProducts.removeAll()
    }
    
    // MARK: - Mock-Specific Methods
    
    /// Check if the mock cache is valid
    /// - Returns: The value of mockCacheValid
    public func isCacheValid() async -> Bool {
        return mockCacheValid
    }
    
    /// Fetch a single product by ID (mock implementation)
    /// - Parameter id: The product identifier
    /// - Returns: IAPProduct if found in mockProducts
    /// - Throws: IAPError if shouldThrowError is set
    public func fetchProduct(id: String) async throws -> IAPProduct? {
        if let error = shouldThrowError {
            throw error
        }
        
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }
        
        fetchCallCount += 1
        lastFetchedProductIds = [id]
        
        return mockProducts.first { $0.id == id }
    }
    
    /// Get the number of times fetchProducts was called
    /// - Returns: Fetch call count
    public func getFetchCallCount() async -> Int {
        return fetchCallCount
    }
    
    /// Get the number of times clearCache was called
    /// - Returns: Clear cache call count
    public func getClearCacheCallCount() async -> Int {
        return clearCacheCallCount
    }
    
    /// Get the product IDs from the last fetchProducts call
    /// - Returns: Array of product IDs
    public func getLastFetchedProductIds() async -> [String] {
        return lastFetchedProductIds
    }
    
    /// Reset all mock state
    public func reset() async {
        mockProducts.removeAll()
        mockCachedProducts.removeAll()
        shouldThrowError = nil
        simulatedDelay = 0
        mockCacheValid = true
        fetchCallCount = 0
        clearCacheCallCount = 0
        lastFetchedProductIds.removeAll()
    }
    
    /// Add a mock product
    /// - Parameter product: The product to add
    public func addMockProduct(_ product: IAPProduct) async {
        mockProducts.append(product)
    }
    
    /// Remove a mock product by ID
    /// - Parameter productId: The product ID to remove
    public func removeMockProduct(id productId: String) async {
        mockProducts.removeAll { $0.id == productId }
        mockCachedProducts.removeAll { $0.id == productId }
    }
    
    /// Set up common test scenarios
    public func setupSuccessfulFetch(products: [IAPProduct]) async {
        mockProducts = products
        mockCachedProducts = products
        shouldThrowError = nil
        mockCacheValid = true
    }
    
    public func setupNetworkError() async {
        shouldThrowError = .networkError
    }
    
    public func setupProductNotFound(productId: String) async {
        shouldThrowError = .productNotFound(productId)
    }
    
    public func setupExpiredCache() async {
        mockCacheValid = false
    }
}

// MARK: - Test Helpers

extension MockProductStore {
    
    /// Create a sample test product
    /// - Parameters:
    ///   - id: Product identifier
    ///   - name: Display name
    ///   - price: Price as string
    ///   - type: Product type
    /// - Returns: IAPProduct for testing
    public static func createTestProduct(
        id: String = "test.product",
        name: String = "Test Product",
        price: String = "$9.99",
        type: ProductType = .nonConsumable
    ) -> IAPProduct {
        return IAPProduct(
            id: id,
            displayName: name,
            description: "Test product description",
            displayPrice: price,
            price: Decimal(9.99),
            type: type
        )
    }
    
    /// Create a sample subscription product
    /// - Parameters:
    ///   - id: Product identifier
    ///   - name: Display name
    ///   - price: Price as string
    ///   - groupId: Subscription group ID
    /// - Returns: IAPProduct for testing subscriptions
    public static func createTestSubscription(
        id: String = "test.subscription",
        name: String = "Test Subscription",
        price: String = "$9.99/month",
        groupId: String = "test.group"
    ) -> IAPProduct {
        return IAPProduct(
            id: id,
            displayName: name,
            description: "Test subscription description",
            displayPrice: price,
            price: Decimal(9.99),
            type: .autoRenewableSubscription,
            subscriptionInfo: SubscriptionInfo(groupId: groupId, period: "P1M")
        )
    }
}