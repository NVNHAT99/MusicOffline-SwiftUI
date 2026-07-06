# Testing

MonetizeKit provides comprehensive mock implementations to facilitate unit testing of your In-App Purchase logic without requiring actual StoreKit transactions.

## Mock Implementations Overview

MonetizeKit includes two main mock classes:

- **MockProductStore**: Simulates product fetching and caching
- **MockPurchases**: Simulates purchase operations and transaction handling

## MockProductStore

A mock implementation of `ProductStoreProtocol` for testing product-related operations.

### Usage

```swift
import XCTest
@testable import MonetizeKit

class ProductTests: XCTestCase {
    var mockStore: MockProductStore!
    
    override func setUp() {
        super.setUp()
        mockStore = MockProductStore()
    }
    
    func testFetchProducts() async throws {
        // Configure mock products
        mockStore.mockProducts = [
            IAPProduct(
                id: "com.app.premium",
                type: .nonConsumable,
                displayName: "Premium",
                description: "Premium features",
                price: 9.99,
                displayPrice: "$9.99"
            )
        ]
        
        // Fetch products
        let products = try await mockStore.fetchProducts(
            productIds: ["com.app.premium"]
        )
        
        XCTAssertEqual(products.count, 1)
        XCTAssertEqual(products.first?.id, "com.app.premium")
    }
    
    func testFetchProductsFailure() async {
        // Configure to throw error
        mockStore.shouldThrowError = true
        
        do {
            _ = try await mockStore.fetchProducts(productIds: ["any"])
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is IAPError)
        }
    }
}
```

### Configuration Properties

| Property | Type | Description |
|----------|------|-------------|
| `mockProducts` | `[IAPProduct]` | Products to return |
| `shouldThrowError` | `Bool` | Whether to throw error |
| `fetchDelay` | `TimeInterval?` | Simulated network delay |
| `fetchCallCount` | `Int` | Number of fetch calls made |

## MockPurchases

A mock implementation of `PurchasesProtocol` for testing purchase flows.

### Usage

```swift
class PurchaseTests: XCTestCase {
    var mockPurchases: MockPurchases!
    
    override func setUp() {
        super.setUp()
        mockPurchases = MockPurchases()
    }
    
    func testSuccessfulPurchase() async throws {
        // Configure successful purchase
        mockPurchases.purchaseResult = .success(
            IAPTransaction(
                id: 12345,
                productId: "com.app.premium",
                purchaseDate: Date(),
                transactionState: .purchased
            )
        )
        
        // Make purchase
        let transaction = try await mockPurchases.purchase(
            productId: "com.app.premium"
        )
        
        XCTAssertEqual(transaction.productId, "com.app.premium")
        XCTAssertEqual(transaction.transactionState, .purchased)
        XCTAssertEqual(mockPurchases.purchaseCallCount, 1)
    }
    
    func testUserCancelledPurchase() async {
        // Configure user cancellation
        mockPurchases.purchaseResult = .failure(.userCancelled)
        
        do {
            _ = try await mockPurchases.purchase(productId: "any")
            XCTFail("Should have thrown userCancelled error")
        } catch IAPError.userCancelled {
            // Expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
}
```

### Configuration Properties

| Property | Type | Description |
|----------|------|-------------|
| `purchaseResult` | `Result<IAPTransaction, IAPError>?` | Purchase result to return |
| `restoredTransactions` | `[IAPTransaction]` | Transactions to restore |
| `purchaseCallCount` | `Int` | Number of purchase calls |
| `restoreCallCount` | `Int` | Number of restore calls |
| `lastPurchasedProductId` | `String?` | Last product ID purchased |

## Testing with Dependency Injection

For better testability, use dependency injection with protocols:

### Define Your Store Manager

```swift
protocol StoreManagerProtocol {
    func fetchProducts() async throws -> [IAPProduct]
    func purchase(productId: String) async throws -> IAPTransaction
    func isEntitled(to productId: String) async -> Bool
}

class StoreManager: StoreManagerProtocol {
    private let productStore: ProductStoreProtocol
    private let purchases: PurchasesProtocol
    
    init(
        productStore: ProductStoreProtocol = ProductStore(),
        purchases: PurchasesProtocol = Purchases()
    ) {
        self.productStore = productStore
        self.purchases = purchases
    }
    
    func fetchProducts() async throws -> [IAPProduct] {
        return try await productStore.fetchProducts(
            productIds: ["com.app.premium"]
        )
    }
    
    func purchase(productId: String) async throws -> IAPTransaction {
        return try await purchases.purchase(productId: productId)
    }
    
    func isEntitled(to productId: String) async -> Bool {
        // Check entitlement logic
        return await purchases.isEntitled(to: productId)
    }
}
```

### Test with Mocks

```swift
class StoreManagerTests: XCTestCase {
    var storeManager: StoreManager!
    var mockProductStore: MockProductStore!
    var mockPurchases: MockPurchases!
    
    override func setUp() {
        super.setUp()
        mockProductStore = MockProductStore()
        mockPurchases = MockPurchases()
        storeManager = StoreManager(
            productStore: mockProductStore,
            purchases: mockPurchases
        )
    }
    
    func testCompleteFlow() async throws {
        // Setup products
        mockProductStore.mockProducts = [
            IAPProduct(
                id: "com.app.premium",
                type: .nonConsumable,
                displayName: "Premium",
                description: "Premium features",
                price: 9.99,
                displayPrice: "$9.99"
            )
        ]
        
        // Setup purchase success
        mockPurchases.purchaseResult = .success(
            IAPTransaction(
                id: 12345,
                productId: "com.app.premium",
                purchaseDate: Date(),
                transactionState: .purchased
            )
        )
        
        // Test flow
        let products = try await storeManager.fetchProducts()
        XCTAssertEqual(products.count, 1)
        
        let transaction = try await storeManager.purchase(
            productId: "com.app.premium"
        )
        XCTAssertEqual(transaction.productId, "com.app.premium")
    }
}
```

## Testing ViewModels

Example of testing a SwiftUI ViewModel:

```swift
@MainActor
class StoreViewModel: ObservableObject {
    @Published var products: [IAPProduct] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let storeManager: StoreManagerProtocol
    
    init(storeManager: StoreManagerProtocol = StoreManager()) {
        self.storeManager = storeManager
    }
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            products = try await storeManager.fetchProducts()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func purchase(_ product: IAPProduct) async {
        do {
            _ = try await storeManager.purchase(productId: product.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### Test the ViewModel

```swift
@MainActor
class StoreViewModelTests: XCTestCase {
    var viewModel: StoreViewModel!
    var mockStoreManager: MockStoreManager!
    
    override func setUp() {
        super.setUp()
        mockStoreManager = MockStoreManager()
        viewModel = StoreViewModel(storeManager: mockStoreManager)
    }
    
    func testLoadProducts() async {
        // Setup mock
        mockStoreManager.productsToReturn = [
            IAPProduct(
                id: "test",
                type: .nonConsumable,
                displayName: "Test",
                description: "Test product",
                price: 1.99,
                displayPrice: "$1.99"
            )
        ]
        
        // Load products
        await viewModel.loadProducts()
        
        // Verify
        XCTAssertEqual(viewModel.products.count, 1)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testLoadProductsError() async {
        // Setup mock to throw error
        mockStoreManager.shouldThrowError = true
        
        // Load products
        await viewModel.loadProducts()
        
        // Verify
        XCTAssertTrue(viewModel.products.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
}
```

## Testing Subscription Scenarios

### Testing Trial Periods

```swift
func testTrialPeriodSubscription() async throws {
    let subscription = IAPTransaction(
        id: 12345,
        productId: "com.app.monthly",
        purchaseDate: Date(),
        expirationDate: Date().addingTimeInterval(7 * 24 * 60 * 60), // 7 days
        transactionState: .purchased,
        offerType: .introductory
    )
    
    mockPurchases.purchaseResult = .success(subscription)
    mockPurchases.mockEntitlements = [
        "com.app.monthly": IAPEntitlement(
            productId: "com.app.monthly",
            isActive: true,
            expirationDate: subscription.expirationDate,
            purchaseDate: subscription.purchaseDate,
            isInTrialPeriod: true,
            isInBillingRetryPeriod: false,
            renewalState: .subscribed
        )
    ]
    
    let transaction = try await mockPurchases.purchase(
        productId: "com.app.monthly"
    )
    
    let isEntitled = await mockPurchases.isEntitled(to: "com.app.monthly")
    let entitlement = mockPurchases.mockEntitlements["com.app.monthly"]
    
    XCTAssertTrue(isEntitled)
    XCTAssertTrue(entitlement?.isInTrialPeriod ?? false)
    XCTAssertEqual(entitlement?.renewalState, .subscribed)
}
```

### Testing Expired Subscriptions

```swift
func testExpiredSubscription() async {
    mockPurchases.mockEntitlements = [
        "com.app.monthly": IAPEntitlement(
            productId: "com.app.monthly",
            isActive: false,
            expirationDate: Date().addingTimeInterval(-86400), // Yesterday
            purchaseDate: Date().addingTimeInterval(-30 * 86400), // 30 days ago
            isInTrialPeriod: false,
            isInBillingRetryPeriod: false,
            renewalState: .expired
        )
    ]
    
    let isEntitled = await mockPurchases.isEntitled(to: "com.app.monthly")
    XCTAssertFalse(isEntitled)
}
```

## Testing Error Scenarios

### Network Errors

```swift
func testNetworkError() async {
    mockProductStore.errorToThrow = IAPError.networkError
    
    do {
        _ = try await mockProductStore.fetchProducts(productIds: ["any"])
        XCTFail("Should throw network error")
    } catch IAPError.networkError {
        // Expected
    } catch {
        XCTFail("Wrong error type")
    }
}
```

### Purchase Not Allowed

```swift
func testPurchaseNotAllowed() async {
    mockPurchases.purchaseResult = .failure(.purchaseNotAllowed)
    
    do {
        _ = try await mockPurchases.purchase(productId: "any")
        XCTFail("Should throw purchaseNotAllowed")
    } catch IAPError.purchaseNotAllowed {
        // Expected
    } catch {
        XCTFail("Wrong error type")
    }
}
```

## Best Practices for Testing

1. **Use Dependency Injection**: Always inject dependencies to make testing easier
2. **Test Edge Cases**: Test error scenarios, network failures, and edge cases
3. **Mock at the Right Level**: Mock at the protocol level, not implementation
4. **Test Async Code Properly**: Use `async`/`await` in tests correctly
5. **Verify State Changes**: Check that your app state updates correctly
6. **Test User Flows**: Test complete user flows, not just individual methods

## Example Test Suite

```swift
import XCTest
@testable import MonetizeKit

final class MonetizeKitTestSuite: XCTestCase {
    var mockProductStore: MockProductStore!
    var mockPurchases: MockPurchases!
    
    override func setUp() {
        super.setUp()
        mockProductStore = MockProductStore()
        mockPurchases = MockPurchases()
    }
    
    override func tearDown() {
        mockProductStore = nil
        mockPurchases = nil
        super.tearDown()
    }
    
    // MARK: - Product Tests
    
    func testFetchProductsSuccess() async throws {
        // Given
        let expectedProducts = createMockProducts()
        mockProductStore.mockProducts = expectedProducts
        
        // When
        let products = try await mockProductStore.fetchProducts(
            productIds: Set(expectedProducts.map { $0.id })
        )
        
        // Then
        XCTAssertEqual(products.count, expectedProducts.count)
        XCTAssertEqual(mockProductStore.fetchCallCount, 1)
    }
    
    // MARK: - Purchase Tests
    
    func testPurchaseSuccess() async throws {
        // Given
        let productId = "com.app.premium"
        let expectedTransaction = createMockTransaction(productId: productId)
        mockPurchases.purchaseResult = .success(expectedTransaction)
        
        // When
        let transaction = try await mockPurchases.purchase(productId: productId)
        
        // Then
        XCTAssertEqual(transaction.productId, productId)
        XCTAssertEqual(transaction.transactionState, .purchased)
        XCTAssertEqual(mockPurchases.lastPurchasedProductId, productId)
    }
    
    // MARK: - Restore Tests
    
    func testRestorePurchases() async throws {
        // Given
        let restoredTransactions = [
            createMockTransaction(productId: "com.app.premium"),
            createMockTransaction(productId: "com.app.subscription")
        ]
        mockPurchases.restoredTransactions = restoredTransactions
        
        // When
        let restored = try await mockPurchases.restorePurchases()
        
        // Then
        XCTAssertEqual(restored.count, 2)
        XCTAssertEqual(mockPurchases.restoreCallCount, 1)
    }
    
    // MARK: - Helper Methods
    
    private func createMockProducts() -> [IAPProduct] {
        return [
            IAPProduct(
                id: "com.app.premium",
                type: .nonConsumable,
                displayName: "Premium",
                description: "Premium features",
                price: 9.99,
                displayPrice: "$9.99"
            ),
            IAPProduct(
                id: "com.app.subscription",
                type: .autoRenewableSubscription,
                displayName: "Monthly Subscription",
                description: "Monthly subscription",
                price: 4.99,
                displayPrice: "$4.99/month"
            )
        ]
    }
    
    private func createMockTransaction(productId: String) -> IAPTransaction {
        return IAPTransaction(
            id: UInt64.random(in: 1...100000),
            productId: productId,
            purchaseDate: Date(),
            transactionState: .purchased
        )
    }
}
```

## Related Documentation

- [IAPManager](IAPManager) - Main manager class
- [Models](Models) - Data model definitions
- [Quick Start](Quick-Start) - Getting started guide
- [Best Practices](Best-Practices) - Testing best practices
