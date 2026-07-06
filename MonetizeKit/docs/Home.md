# MonetizeKit API Documentation

Welcome to the MonetizeKit API documentation. MonetizeKit is a comprehensive Swift package for iOS monetization with StoreKit 2 integration.

## 📚 Documentation Index

### Getting Started
- [Installation](Installation) - How to add MonetizeKit to your project
- [Quick Start Guide](Quick-Start) - Get up and running quickly
- [Configuration](Configuration) - Initial setup and configuration

### Core Components
- [IAPManager](IAPManager) - Central manager for all IAP operations
- [ProductStore](ProductStore) - Product fetching and caching
- [Purchases](Purchases) - Purchase flow and transaction handling

### Data Models & Types
- [Models](Models) - Core data models (IAPProduct, IAPTransaction, etc.)
- [Protocols](Protocols) - Protocol definitions and conformance
- [Error Types](Error-Types) - Error handling and custom error types

### Advanced Topics
- [Transaction Verification](Transaction-Verification) - Implementing receipt validation
- [Entitlement Management](Entitlement-Management) - Managing user entitlements
- [Testing & Mocking](Testing) - Unit testing with mock implementations

### Examples
- [Code Examples](Examples) - Common use cases and implementations
- [SwiftUI Integration](SwiftUI-Integration) - Using MonetizeKit with SwiftUI
- [Best Practices](Best-Practices) - Recommended patterns and practices

## 🎯 Key Features

- **StoreKit 2 Integration**: Built on Apple's latest StoreKit framework
- **Async/Await Support**: Modern Swift concurrency patterns
- **Type Safety**: Comprehensive error handling with custom error types
- **Testing Support**: Complete mock implementations for unit testing
- **Caching**: Intelligent product caching for better performance
- **Transaction Observation**: Real-time transaction monitoring
- **iOS 15+**: Targets iOS 15+ with modern Swift features

## 🚀 Quick Example

```swift
import MonetizeKit

// Configure MonetizeKit
await IAPManager.shared.configure(
    productIds: ["com.app.premium", "com.app.subscription"]
)

// Fetch products
let products = try await IAPManager.shared.fetchProducts()

// Make a purchase
let transaction = try await IAPManager.shared.purchase(productId: "com.app.premium")

// Check entitlements
let isPremium = await IAPManager.shared.isEntitled(to: "com.app.premium")
```

## 📋 Requirements

- iOS 15.0+
- Swift 5.7+
- Xcode 14.0+

## 📖 API Reference

Browse the complete API reference organized by component:

| Component | Description |
|-----------|-------------|
| [IAPManager](IAPManager) | Central manager for IAP operations |
| [ProductStore](ProductStore) | Product management and caching |
| [Purchases](Purchases) | Purchase flow handling |
| [IAPProduct](Models#iapproduct) | Product model |
| [IAPTransaction](Models#iaptransaction) | Transaction model |
| [IAPError](Error-Types#iaperror) | Error types |

## 🔗 Resources

- [GitHub Repository](https://github.com/phuongddx/MonetizeKit)
- [Apple StoreKit Documentation](https://developer.apple.com/documentation/storekit)
- [WWDC StoreKit Videos](https://developer.apple.com/videos/frameworks/storekit)

---

*Last updated: August 2024*
