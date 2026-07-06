# MonetizeKit

A complete, modular Swift Package Manager (SPM) library for handling In-App Purchases using StoreKit 2. Built for iOS 15+ with Swift 5.7+, MonetizeKit provides a modern, async/await-based API for managing IAP operations with built-in caching, transaction observation, and entitlement tracking.

## 📚 Documentation

- **[Full API Documentation](https://github.com/phuongddx/MonetizeKit/tree/wiki-docs/docs)** - Complete API reference and guides
- **[Quick Start Guide](https://github.com/phuongddx/MonetizeKit/blob/wiki-docs/docs/Quick-Start.md)** - Get up and running quickly
- **[Installation Guide](https://github.com/phuongddx/MonetizeKit/blob/wiki-docs/docs/Installation.md)** - Detailed installation instructions

## Features

- ✅ **StoreKit 2 Integration**: Built on Apple's latest StoreKit framework
- 🎯 **Product Management**: Fetch, cache, and manage IAP products
- 💰 **Purchase Flow**: Handle purchases, restorations, and transaction observation
- 🔐 **Entitlement Tracking**: Real-time entitlement streaming and management
- ✅ **Transaction Verification**: Protocol-based verification system (with production guidelines)
- 🧪 **Testing Support**: Complete mock implementations for unit testing
- 🔒 **Type Safety**: Comprehensive error handling with custom error types
- ⚡ **Performance**: Actor-based concurrency and intelligent caching
- 📱 **iOS 15+**: Targets iOS 15+ with modern Swift features

## Supported Product Types

- **Consumables**: Items that can be purchased multiple times
- **Non-Consumables**: One-time purchases
- **Auto-Renewable Subscriptions**: Recurring subscriptions
- **Non-Renewable Subscriptions**: Time-limited subscriptions

## Installation

### Swift Package Manager

Add MonetizeKit to your project using Xcode:

1. In Xcode, go to **File → Add Package Dependencies**
2. Enter the repository URL: `https://github.com/yourorg/MonetizeKit`
3. Choose the version and add to your target

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourorg/MonetizeKit", from: "1.0.0")
]
```

## Quick Start

### 1. Configure MonetizeKit

Configure MonetizeKit early in your app's lifecycle (e.g., in `App.init()` or `AppDelegate`):

```swift
import MonetizeKit

@main
struct MyApp: App {
    init() {
        Task {
            do {
                await IAPManager.shared.configure(productIds: [
                    "com.myapp.premium",
                    "com.myapp.monthly_subscription",
                    "com.myapp.yearly_subscription"
                ])
            } catch {
                print("IAP configuration failed: \(error)")
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 2. Fetch Products

```swift
import MonetizeKit

class StoreViewModel: ObservableObject {
    @Published var products: [IAPProduct] = []
    @Published var isLoading = false
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            products = try await IAPManager.shared.products()
        } catch {
            print("Failed to load products: \(error)")
        }
    }
}
```

### 3. Make a Purchase

```swift
func purchaseProduct(_ product: IAPProduct) async {
    do {
        let transaction = try await IAPManager.shared.purchase(product)
        
        // Process the successful purchase
        print("Purchase successful: \(transaction.productID)")
        
        // Finish the transaction
        await IAPManager.shared.finishTransaction(transaction)
        
    } catch IAPError.purchaseCancelled {
        print("Purchase was cancelled by user")
    } catch {
        print("Purchase failed: \(error)")
    }
}
```

### 4. Observe Entitlements

```swift
class EntitlementManager: ObservableObject {
    @Published var hasPremium = false
    @Published var hasActiveSubscription = false
    
    func startObserving() {
        Task {
            for await entitlements in IAPManager.shared.entitlementsStream {
                await MainActor.run {
                    hasPremium = entitlements.contains { 
                        $0.productId == "com.myapp.premium" && $0.isActive 
                    }
                    hasActiveSubscription = entitlements.contains { 
                        $0.productId.contains("subscription") && $0.isActive 
                    }
                }
            }
        }
    }
}
```

### 5. Restore Purchases

```swift
func restorePurchases() async {
    do {
        let restoredTransactions = try await IAPManager.shared.restorePurchases()
        print("Restored \(restoredTransactions.count) transactions")
    } catch {
        print("Restore failed: \(error)")
    }
}
```

## Advanced Usage

### Custom Verification

For production apps, implement proper transaction verification:

```swift
import MonetizeKit

public class ProductionVerifier: VerificationProtocol {
    private let backendURL: URL
    private let apiKey: String
    
    public init(backendURL: URL, apiKey: String) {
        self.backendURL = backendURL
        self.apiKey = apiKey
    }
    
    public func verify(transaction: Transaction) async throws -> Bool {
        // Implement server-side verification
        // Send transaction to your backend for validation
        // Return verification result
    }
    
    public func verifyJWS(_ jwsRepresentation: String) async throws -> Bool {
        // Implement JWS verification
        // Use Apple's public keys to verify the signature
        // Validate the payload data
    }
}

// Use with custom verifier
let customPurchases = Purchases(verifier: ProductionVerifier(
    backendURL: URL(string: "https://api.myapp.com")!,
    apiKey: "your-api-key"
))

let iapManager = IAPManager(purchases: customPurchases)
```

### Checking Specific Entitlements

```swift
// Check for specific premium features
let hasPremium = await IAPManager.shared.hasActiveEntitlement(for: "com.myapp.premium")

// Get detailed entitlement information
if let entitlement = await IAPManager.shared.entitlement(for: "com.myapp.monthly") {
    print("Subscription expires: \(entitlement.expirationDate)")
    print("Is active: \(entitlement.isActive)")
}
```

### Handling Different Product Types

```swift
// Get products by type
let subscriptions = try await IAPManager.shared.subscriptionProducts()
let consumables = try await IAPManager.shared.consumableProducts()
let nonConsumables = try await IAPManager.shared.nonConsumableProducts()

// Handle consumables (finish immediately)
if product.type == .consumable {
    let transaction = try await IAPManager.shared.purchase(product)
    await IAPManager.shared.finishTransaction(transaction)
    // Grant consumable benefit immediately
}
```

## Testing

MonetizeKit includes comprehensive mock implementations for testing:

```swift
import MonetizeKit
import XCTest

class IAPTests: XCTestCase {
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
    
    func testSuccessfulPurchase() async throws {
        // Setup mock products
        let testProduct = MockProductStore.createTestProduct(
            id: "test.product",
            name: "Test Product",
            price: "$9.99"
        )
        await mockProductStore.addMockProduct(testProduct)
        await mockPurchases.setupSuccessfulPurchase()
        
        // Configure and test
        try await iapManager.configure(productIds: ["test.product"])
        let transaction = try await iapManager.purchase(testProduct)
        
        XCTAssertEqual(transaction.productID, "test.product")
    }
    
    func testCancelledPurchase() async {
        await mockPurchases.setupCancelledPurchase()
        
        do {
            _ = try await iapManager.purchase(testProduct)
            XCTFail("Expected cancellation error")
        } catch IAPError.purchaseCancelled {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
```

## Error Handling

MonetizeKit provides comprehensive error handling:

```swift
do {
    let transaction = try await IAPManager.shared.purchase(product)
} catch IAPError.productNotFound(let productId) {
    print("Product not found: \(productId)")
} catch IAPError.purchaseCancelled {
    print("User cancelled the purchase")
} catch IAPError.purchaseFailed(let reason) {
    print("Purchase failed: \(reason)")
} catch IAPError.verificationFailed(let reason) {
    print("Verification failed: \(reason)")
} catch IAPError.networkError {
    print("Network error occurred")
} catch {
    print("Unexpected error: \(error)")
}
```

## Production Considerations

### ⚠️ Transaction Verification

The included `NoOpVerifier` is **NOT suitable for production**. For production apps:

1. **Implement server-side verification** using Apple's App Store Server API
2. **Use JWS verification** with Apple's public keys
3. **Store verified transactions** in your backend
4. **Implement proper error handling** and retry logic

### Subscription Management

- **Monitor subscription status** using App Store Server Notifications
- **Handle subscription lifecycle events** (renewals, cancellations, billing issues)
- **Implement grace periods** and billing retry logic
- **Provide subscription management** UI linking to App Store

### Security Best Practices

- **Never trust client-side verification alone** for critical decisions
- **Always validate transactions server-side** for payment processing
- **Implement replay attack protection** using transaction IDs
- **Use HTTPS** for all communication with your backend
- **Store verification results** for audit and troubleshooting

## Architecture

MonetizeKit follows SOLID principles and clean architecture:

```
┌─────────────────┐
│   IAPManager    │  ← Main Facade (Actor)
│    (Facade)     │
└─────────────────┘
         │
    ┌────┴────┐
    │         │
┌───▼──┐ ┌───▼──┐
│Product│ │Purchases│  ← Core Services (Actors)
│Store  │ │        │
└───────┘ └────────┘
         │
    ┌────▼────┐
    │Verification│  ← Verification Protocol
    │Protocol   │
    └─────────┘
```

### Key Components

- **IAPManager**: Main facade providing simplified API
- **ProductStore**: Handles product fetching and caching
- **Purchases**: Manages purchase flow and transaction observation
- **Verification**: Protocol for transaction verification
- **Models**: Type-safe data models and error types
- **Extensions**: Helper extensions for StoreKit types

## Requirements

- iOS 15.0+
- Swift 5.7+
- Xcode 14.0+

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MonetizeKit is available under the MIT license. See the LICENSE file for more info.

## Support

- 📖 **Documentation**: [Full API Documentation](https://yourorg.github.io/MonetizeKit)
- 🐛 **Issues**: [GitHub Issues](https://github.com/yourorg/MonetizeKit/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/yourorg/MonetizeKit/discussions)

---

Made with ❤️ for the iOS developer community