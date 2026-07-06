# IAPManager

The `IAPManager` is the central component of MonetizeKit, providing a unified interface for all In-App Purchase operations. It follows the singleton pattern and manages product fetching, purchases, transaction observation, and entitlement tracking.

## Overview

```swift
@MainActor
public final class IAPManager: ObservableObject
```

## Singleton Instance

```swift
public static let shared = IAPManager()
```

Access the shared instance throughout your app using `IAPManager.shared`.

## Properties

### Published Properties

| Property | Type | Description |
|----------|------|-------------|
| `products` | `[IAPProduct]` | Currently loaded products |
| `purchasedProductIds` | `Set<String>` | Set of purchased product IDs |
| `entitlements` | `[String: IAPEntitlement]` | Current user entitlements |
| `isProcessingPurchase` | `Bool` | Whether a purchase is in progress |

### Async Streams

```swift
public var transactionUpdates: AsyncStream<IAPTransaction>
```

An async stream that emits transaction updates in real-time.

## Methods

### Configuration

#### `configure(productIds:verificationProvider:)`

Initialize MonetizeKit with your product identifiers.

```swift
public func configure(
    productIds: Set<String>,
    verificationProvider: TransactionVerificationProvider? = nil
) async
```

**Parameters:**
- `productIds`: Set of product identifiers from App Store Connect
- `verificationProvider`: Optional custom verification provider

**Example:**
```swift
await IAPManager.shared.configure(
    productIds: [
        "com.app.premium",
        "com.app.removeads",
        "com.app.subscription.monthly"
    ]
)
```

### Product Management

#### `fetchProducts()`

Fetch products from the App Store.

```swift
public func fetchProducts() async throws -> [IAPProduct]
```

**Returns:** Array of `IAPProduct` objects

**Throws:** `IAPError` if products cannot be fetched

**Example:**
```swift
do {
    let products = try await IAPManager.shared.fetchProducts()
    print("Loaded \(products.count) products")
} catch {
    print("Failed to fetch products: \(error)")
}
```

#### `product(for:)`

Get a specific product by ID.

```swift
public func product(for productId: String) async -> IAPProduct?
```

**Parameters:**
- `productId`: The product identifier

**Returns:** `IAPProduct` if found, nil otherwise

**Example:**
```swift
if let product = await IAPManager.shared.product(for: "com.app.premium") {
    print("Product: \(product.displayName) - \(product.displayPrice)")
}
```

### Purchase Operations

#### `purchase(productId:options:)`

Purchase a product.

```swift
public func purchase(
    productId: String,
    options: Set<Product.PurchaseOption> = []
) async throws -> IAPTransaction
```

**Parameters:**
- `productId`: The product identifier to purchase
- `options`: Optional purchase options (e.g., promotional offers)

**Returns:** `IAPTransaction` representing the completed purchase

**Throws:** 
- `IAPError.productNotFound` if product doesn't exist
- `IAPError.purchaseNotAllowed` if purchases are disabled
- `IAPError.userCancelled` if user cancels
- Other `IAPError` cases for various failure scenarios

**Example:**
```swift
do {
    let transaction = try await IAPManager.shared.purchase(
        productId: "com.app.premium"
    )
    print("Purchase successful: \(transaction.id)")
} catch IAPError.userCancelled {
    print("User cancelled purchase")
} catch {
    print("Purchase failed: \(error)")
}
```

#### `purchase(product:options:)`

Purchase a product using an `IAPProduct` instance.

```swift
public func purchase(
    product: IAPProduct,
    options: Set<Product.PurchaseOption> = []
) async throws -> IAPTransaction
```

**Parameters:**
- `product`: The `IAPProduct` to purchase
- `options`: Optional purchase options

**Returns:** `IAPTransaction` representing the completed purchase

### Transaction Management

#### `restorePurchases()`

Restore previous purchases.

```swift
public func restorePurchases() async throws -> [IAPTransaction]
```

**Returns:** Array of restored `IAPTransaction` objects

**Throws:** `IAPError` if restoration fails

**Example:**
```swift
do {
    let restoredTransactions = try await IAPManager.shared.restorePurchases()
    print("Restored \(restoredTransactions.count) purchases")
} catch {
    print("Restoration failed: \(error)")
}
```

#### `finishTransaction(_:)`

Manually finish a transaction (usually handled automatically).

```swift
public func finishTransaction(_ transaction: IAPTransaction) async
```

**Parameters:**
- `transaction`: The transaction to finish

### Entitlement Management

#### `isEntitled(to:)`

Check if user is entitled to a product.

```swift
public func isEntitled(to productId: String) async -> Bool
```

**Parameters:**
- `productId`: The product identifier to check

**Returns:** `true` if user has valid entitlement, `false` otherwise

**Example:**
```swift
let hasPremium = await IAPManager.shared.isEntitled(to: "com.app.premium")
if hasPremium {
    // Unlock premium features
}
```

#### `entitlement(for:)`

Get detailed entitlement information.

```swift
public func entitlement(for productId: String) async -> IAPEntitlement?
```

**Parameters:**
- `productId`: The product identifier

**Returns:** `IAPEntitlement` object if entitled, nil otherwise

**Example:**
```swift
if let entitlement = await IAPManager.shared.entitlement(for: "com.app.subscription") {
    print("Expires: \(entitlement.expirationDate ?? Date())")
    print("Is in trial: \(entitlement.isInTrialPeriod)")
}
```

#### `refreshEntitlements()`

Manually refresh all entitlements.

```swift
public func refreshEntitlements() async
```

**Example:**
```swift
await IAPManager.shared.refreshEntitlements()
```

### Subscription Management

#### `activeSubscriptions()`

Get all active subscriptions.

```swift
public func activeSubscriptions() async -> [IAPProduct]
```

**Returns:** Array of active subscription products

**Example:**
```swift
let subscriptions = await IAPManager.shared.activeSubscriptions()
for subscription in subscriptions {
    print("Active: \(subscription.displayName)")
}
```

#### `subscriptionStatus(for:)`

Get detailed subscription status.

```swift
public func subscriptionStatus(for productId: String) async -> SubscriptionStatus?
```

**Parameters:**
- `productId`: The subscription product identifier

**Returns:** `SubscriptionStatus` if available, nil otherwise

## Transaction Observation

### Observing Transaction Updates

Monitor real-time transaction updates:

```swift
Task {
    for await transaction in IAPManager.shared.transactionUpdates {
        switch transaction.transactionState {
        case .purchased:
            print("New purchase: \(transaction.productId)")
        case .restored:
            print("Restored: \(transaction.productId)")
        case .failed:
            print("Failed: \(transaction.productId)")
        default:
            break
        }
    }
}
```

## Error Handling

IAPManager methods throw `IAPError` with specific error cases:

```swift
public enum IAPError: LocalizedError {
    case configurationError
    case productNotFound
    case purchaseNotAllowed
    case purchaseFailed(underlying: Error?)
    case verificationFailed
    case restoreFailed
    case userCancelled
    case networkError
    case unknown
}
```

Handle errors appropriately:

```swift
do {
    let transaction = try await IAPManager.shared.purchase(productId: "product_id")
} catch IAPError.userCancelled {
    // User cancelled - no action needed
} catch IAPError.productNotFound {
    showAlert("Product not available")
} catch IAPError.purchaseNotAllowed {
    showAlert("Purchases are disabled on this device")
} catch IAPError.networkError {
    showAlert("Network error. Please try again.")
} catch {
    showAlert("Purchase failed: \(error.localizedDescription)")
}
```

## Best Practices

1. **Initialize Early**: Configure IAPManager in your app's initialization
2. **Cache Products**: Products are automatically cached after fetching
3. **Handle All Errors**: Always provide appropriate error handling
4. **Observe Transactions**: Use transaction updates for real-time updates
5. **Check Entitlements**: Always verify entitlements before unlocking features

## Thread Safety

IAPManager is marked with `@MainActor` to ensure UI updates happen on the main thread. All async methods can be safely called from any context.

## Example: Complete Integration

```swift
import MonetizeKit

class StoreManager: ObservableObject {
    @Published var products: [IAPProduct] = []
    @Published var isPremium = false
    
    init() {
        Task {
            // Configure
            await IAPManager.shared.configure(
                productIds: ["com.app.premium", "com.app.subscription"]
            )
            
            // Load products
            await loadProducts()
            
            // Check entitlements
            await updatePremiumStatus()
            
            // Observe transactions
            observeTransactions()
        }
    }
    
    func loadProducts() async {
        do {
            products = try await IAPManager.shared.fetchProducts()
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: IAPProduct) async throws {
        let transaction = try await IAPManager.shared.purchase(product: product)
        await updatePremiumStatus()
    }
    
    func restore() async throws {
        _ = try await IAPManager.shared.restorePurchases()
        await updatePremiumStatus()
    }
    
    private func updatePremiumStatus() async {
        isPremium = await IAPManager.shared.isEntitled(to: "com.app.premium") ||
                   await IAPManager.shared.isEntitled(to: "com.app.subscription")
    }
    
    private func observeTransactions() {
        Task {
            for await _ in IAPManager.shared.transactionUpdates {
                await updatePremiumStatus()
            }
        }
    }
}
```

## Related Documentation

- [ProductStore](ProductStore) - Product caching and management
- [Purchases](Purchases) - Purchase flow implementation
- [Models](Models) - Data model definitions
- [Testing](Testing) - Testing with mock implementations
