import XCTest
@testable import MonetizeKit

/// Basic test file for MonetizeKit
/// 
/// This file provides a starting point for unit tests. Expand these tests
/// to cover your specific use cases and business logic.
final class MonetizeKitTests: XCTestCase {
    
    func testIAPErrorEquality() {
        let error1 = IAPError.productNotFound("test.product")
        let error2 = IAPError.productNotFound("test.product")
        let error3 = IAPError.productNotFound("different.product")
        
        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }
    
    func testEntitlementCreation() {
        let entitlement = Entitlement(
            productId: "test.product",
            isActive: true,
            purchaseDate: Date(),
            expirationDate: Date().addingTimeInterval(3600),
            originalTransactionId: "12345"
        )
        
        XCTAssertEqual(entitlement.productId, "test.product")
        XCTAssertTrue(entitlement.isActive)
        XCTAssertTrue(entitlement.isSubscription)
        XCTAssertFalse(entitlement.isExpired)
    }
    
    func testIAPProductCreation() {
        let product = IAPProduct(
            id: "test.product",
            displayName: "Test Product",
            description: "A test product",
            displayPrice: "$9.99",
            price: Decimal(9.99),
            type: .nonConsumable
        )
        
        XCTAssertEqual(product.id, "test.product")
        XCTAssertEqual(product.displayName, "Test Product")
        XCTAssertEqual(product.type, .nonConsumable)
        XCTAssertNil(product.subscriptionInfo)
    }
    
    func testSubscriptionProductCreation() {
        let subscriptionInfo = SubscriptionInfo(
            groupId: "test.group",
            period: "P1M"
        )
        
        let product = IAPProduct(
            id: "test.subscription",
            displayName: "Test Subscription",
            description: "A test subscription",
            displayPrice: "$9.99/month",
            price: Decimal(9.99),
            type: .autoRenewableSubscription,
            subscriptionInfo: subscriptionInfo
        )
        
        XCTAssertEqual(product.id, "test.subscription")
        XCTAssertEqual(product.type, .autoRenewableSubscription)
        XCTAssertNotNil(product.subscriptionInfo)
        XCTAssertEqual(product.subscriptionInfo?.groupId, "test.group")
    }
}

// MARK: - Mock Tests

final class MockProductStoreTests: XCTestCase {
    
    var mockStore: MockProductStore!
    
    override func setUp() async throws {
        mockStore = MockProductStore()
    }
    
    override func tearDown() async throws {
        await mockStore.reset()
        mockStore = nil
    }
    
    func testMockProductStoreBasicFunctionality() async throws {
        // Setup
        let testProduct = MockProductStore.createTestProduct(
            id: "test.product",
            name: "Test Product",
            price: "$9.99"
        )
        await mockStore.addMockProduct(testProduct)
        
        // Test fetch
        let products = try await mockStore.fetchProducts(productIds: ["test.product"])
        XCTAssertEqual(products.count, 1)
        XCTAssertEqual(products.first?.id, "test.product")
        
        // Test cache
        let cachedProducts = await mockStore.getCachedProducts()
        XCTAssertEqual(cachedProducts.count, 1)
        
        // Test get specific product
        let specificProduct = await mockStore.getProduct(id: "test.product")
        XCTAssertNotNil(specificProduct)
        XCTAssertEqual(specificProduct?.id, "test.product")
    }
    
    func testMockProductStoreErrorScenarios() async {
        // Test product not found
        do {
            _ = try await mockStore.fetchProducts(productIds: ["nonexistent.product"])
            XCTFail("Expected product not found error")
        } catch IAPError.productNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Test network error
        await mockStore.setupNetworkError()
        do {
            _ = try await mockStore.fetchProducts(productIds: ["test.product"])
            XCTFail("Expected network error")
        } catch IAPError.networkError {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

final class MockPurchasesTests: XCTestCase {
    
    var mockPurchases: MockPurchases!
    
    override func setUp() async throws {
        mockPurchases = MockPurchases()
    }
    
    override func tearDown() async throws {
        await mockPurchases.reset()
        mockPurchases = nil
    }
    
    func testMockPurchasesBasicFunctionality() async throws {
        // Setup successful purchase
        await mockPurchases.setupSuccessfulPurchase()
        
        let testProduct = IAPProduct(
            id: "test.product",
            displayName: "Test Product",
            description: "A test product",
            displayPrice: "$9.99",
            price: Decimal(9.99),
            type: .nonConsumable
        )
        
        // Test purchase
        let transaction = try await mockPurchases.purchase(testProduct)
        XCTAssertEqual(transaction.productID, "test.product")
        
        // Test entitlement was created
        let entitlements = await mockPurchases.getCurrentEntitlements()
        XCTAssertEqual(entitlements.count, 1)
        XCTAssertEqual(entitlements.first?.productId, "test.product")
        XCTAssertTrue(entitlements.first?.isActive == true)
        
        // Test has active entitlement
        let hasEntitlement = await mockPurchases.hasActiveEntitlement(for: "test.product")
        XCTAssertTrue(hasEntitlement)
    }
    
    func testMockPurchasesCancellation() async {
        await mockPurchases.setupCancelledPurchase()
        
        let testProduct = IAPProduct(
            id: "test.product",
            displayName: "Test Product",
            description: "A test product",
            displayPrice: "$9.99",
            price: Decimal(9.99),
            type: .nonConsumable
        )
        
        do {
            _ = try await mockPurchases.purchase(testProduct)
            XCTFail("Expected cancellation error")
        } catch IAPError.purchaseCancelled {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - Integration Tests

final class IAPManagerIntegrationTests: XCTestCase {
    
    var mockProductStore: MockProductStore!
    var mockPurchases: MockPurchases!
    var iapManager: IAPManager!
    
    override func setUp() async throws {
        mockProductStore = MockProductStore()
        mockPurchases = MockPurchases()
        iapManager = IAPManager(
            productStore: mockProductStore,
            purchases: mockPurchases
        )
    }
    
    override func tearDown() async throws {
        await mockProductStore.reset()
        await mockPurchases.reset()
        await iapManager.cleanup()
        mockProductStore = nil
        mockPurchases = nil
        iapManager = nil
    }
    
    func testIAPManagerConfiguration() async throws {
        let productIds = ["test.product1", "test.product2"]
        
        // Add mock products
        for productId in productIds {
            let product = MockProductStore.createTestProduct(id: productId)
            await mockProductStore.addMockProduct(product)
        }
        
        // Configure
        try await iapManager.configure(productIds: productIds)
        
        // Verify configuration
        let isConfigured = await iapManager.isConfigured()
        XCTAssertTrue(isConfigured)
        
        let configuredIds = await iapManager.getConfiguredProductIds()
        XCTAssertEqual(Set(configuredIds), Set(productIds))
    }
    
    func testEndToEndPurchaseFlow() async throws {
        // Setup
        let testProduct = MockProductStore.createTestProduct(
            id: "test.premium",
            name: "Premium Features",
            price: "$4.99"
        )
        
        await mockProductStore.addMockProduct(testProduct)
        await mockPurchases.setupSuccessfulPurchase()
        
        // Configure
        try await iapManager.configure(productIds: ["test.premium"])
        
        // Fetch products
        let products = try await iapManager.products()
        XCTAssertEqual(products.count, 1)
        XCTAssertEqual(products.first?.id, "test.premium")
        
        // Make purchase
        guard let product = products.first else {
            XCTFail("Product not found")
            return
        }
        
        let transaction = try await iapManager.purchase(product)
        XCTAssertEqual(transaction.productID, "test.premium")
        
        // Verify entitlement
        let hasEntitlement = await iapManager.hasActiveEntitlement(for: "test.premium")
        XCTAssertTrue(hasEntitlement)
        
        // Finish transaction
        await iapManager.finishTransaction(transaction)
    }
}