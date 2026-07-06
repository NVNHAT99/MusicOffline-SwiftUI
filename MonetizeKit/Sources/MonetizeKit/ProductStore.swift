import Foundation
import StoreKit

/// Actor responsible for fetching and caching App Store products
public actor ProductStore: ProductStoreProtocol {
    
    private var cachedProducts: [String: IAPProduct] = [:]
    private var lastFetchTime: Date?
    private let cacheExpirationInterval: TimeInterval = 300 // 5 minutes
    
    public init() {}
    
    // MARK: - ProductStoreProtocol Implementation
    
    /// Fetch products from the App Store
    /// - Parameter productIds: Array of product identifiers to fetch
    /// - Returns: Array of IAPProduct objects
    /// - Throws: IAPError if fetching fails
    public func fetchProducts(productIds: [String]) async throws -> [IAPProduct] {
        guard !productIds.isEmpty else {
            return []
        }
        
        do {
            let storeProducts = try await Product.products(for: productIds)
            let iapProducts = storeProducts.map { IAPProduct(from: $0) }
            
            // Update cache
            for product in iapProducts {
                cachedProducts[product.id] = product
            }
            lastFetchTime = Date()
            
            // Check for missing products
            let foundProductIds = Set(iapProducts.map { $0.id })
            let missingProductIds = Set(productIds).subtracting(foundProductIds)
            
            if !missingProductIds.isEmpty {
                let missingIds = Array(missingProductIds).joined(separator: ", ")
                throw IAPError.productNotFound("Products not found: \(missingIds)")
            }
            
            return iapProducts
        } catch {
            if let iapError = error as? IAPError {
                throw iapError
            }
            throw IAPError.storeKitError(error)
        }
    }
    
    /// Get cached products
    /// - Returns: Array of cached IAPProduct objects
    public func getCachedProducts() async -> [IAPProduct] {
        // Check if cache is expired
        if let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) > cacheExpirationInterval {
            // Cache is expired but we'll still return cached products
            // The caller can choose to refresh if needed
        }
        
        return Array(cachedProducts.values)
    }
    
    /// Get a specific product by ID
    /// - Parameter productId: The product identifier
    /// - Returns: IAPProduct if found, nil otherwise
    public func getProduct(id productId: String) async -> IAPProduct? {
        return cachedProducts[productId]
    }
    
    /// Clear the product cache
    public func clearCache() async {
        cachedProducts.removeAll()
        lastFetchTime = nil
    }
    
    /// Fetch a single product by ID
    /// - Parameter id: The product identifier
    /// - Returns: IAPProduct if found
    /// - Throws: IAPError if fetching fails
    public func fetchProduct(id: String) async throws -> IAPProduct? {
        let products = try await fetchProducts(productIds: [id])
        return products.first
    }
    
    // MARK: - Helper Methods
    
    /// Check if the cache is valid (not expired)
    /// - Returns: True if cache is valid, false if expired
    public func isCacheValid() async -> Bool {
        guard let lastFetch = lastFetchTime else {
            return false
        }
        return Date().timeIntervalSince(lastFetch) <= cacheExpirationInterval
    }
    
    /// Get the number of cached products
    /// - Returns: Count of cached products
    public func getCachedProductCount() async -> Int {
        return cachedProducts.count
    }
    
    /// Fetch a single product by ID
    /// - Parameter productId: The product identifier
    /// - Returns: IAPProduct if found
    /// - Throws: IAPError if product not found or fetching fails
    public func fetchProduct(id productId: String) async throws -> IAPProduct {
        let products = try await fetchProducts(productIds: [productId])
        guard let product = products.first else {
            throw IAPError.productNotFound(productId)
        }
        return product
    }
}
