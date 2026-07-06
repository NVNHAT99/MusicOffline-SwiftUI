# Quick Start Guide

Get up and running with MonetizeKit in minutes. This guide covers the essential steps to integrate In-App Purchases into your iOS app.

## Basic Setup

### 1. Configure MonetizeKit

Initialize MonetizeKit early in your app's lifecycle (e.g., in your App's init or AppDelegate):

```swift
import MonetizeKit

@main
struct MyApp: App {
    init() {
        Task {
            await IAPManager.shared.configure(
                productIds: [
                    "com.myapp.premium",
                    "com.myapp.remove_ads",
                    "com.myapp.monthly_subscription",
                    "com.myapp.yearly_subscription"
                ]
            )
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

Retrieve available products from the App Store:

```swift
class StoreViewModel: ObservableObject {
    @Published var products: [IAPProduct] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            products = try await IAPManager.shared.fetchProducts()
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
```

### 3. Display Products

Show products in your UI:

```swift
struct StoreView: View {
    @StateObject private var viewModel = StoreViewModel()
    
    var body: some View {
        NavigationView {
            List(viewModel.products) { product in
                HStack {
                    VStack(alignment: .leading) {
                        Text(product.displayName)
                            .font(.headline)
                        Text(product.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(product.displayPrice) {
                        Task {
                            await purchaseProduct(product)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Store")
            .task {
                await viewModel.loadProducts()
            }
        }
    }
    
    func purchaseProduct(_ product: IAPProduct) async {
        do {
            let transaction = try await IAPManager.shared.purchase(
                productId: product.id
            )
            print("Purchase successful: \(transaction.productId)")
        } catch {
            print("Purchase failed: \(error)")
        }
    }
}
```

## Common Use Cases

### Check if User Has Active Subscription

```swift
func checkSubscriptionStatus() async -> Bool {
    let subscriptionIds = [
        "com.myapp.monthly_subscription",
        "com.myapp.yearly_subscription"
    ]
    
    for productId in subscriptionIds {
        if await IAPManager.shared.isEntitled(to: productId) {
            return true
        }
    }
    
    return false
}
```

### Restore Purchases

```swift
func restorePurchases() async {
    do {
        let restored = try await IAPManager.shared.restorePurchases()
        print("Restored \(restored.count) purchases")
        
        // Update UI based on restored purchases
        for transaction in restored {
            print("Restored: \(transaction.productId)")
        }
    } catch {
        print("Restore failed: \(error)")
    }
}
```

### Listen for Transaction Updates

```swift
class PurchaseObserver: ObservableObject {
    @Published var hasActiveSubscription = false
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        observeTransactions()
    }
    
    func observeTransactions() {
        Task {
            for await transaction in IAPManager.shared.transactionUpdates {
                // Handle transaction update
                await updateEntitlements()
            }
        }
    }
    
    func updateEntitlements() async {
        hasActiveSubscription = await checkSubscriptionStatus()
    }
}
```

## Complete Example

Here's a complete SwiftUI view implementing a simple store:

```swift
import SwiftUI
import MonetizeKit

struct SimpleStoreView: View {
    @State private var products: [IAPProduct] = []
    @State private var isLoading = false
    @State private var purchaseInProgress = false
    @State private var message: String?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading products...")
                        .padding()
                } else if products.isEmpty {
                    Text("No products available")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List(products) { product in
                        ProductRow(
                            product: product,
                            onPurchase: { await purchase(product) }
                        )
                    }
                }
                
                if let message = message {
                    Text(message)
                        .foregroundColor(.green)
                        .padding()
                }
            }
            .navigationTitle("Store")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Restore") {
                        Task { await restore() }
                    }
                }
            }
            .task {
                await loadProducts()
            }
            .disabled(purchaseInProgress)
        }
    }
    
    func loadProducts() async {
        isLoading = true
        do {
            products = try await IAPManager.shared.fetchProducts()
        } catch {
            message = "Failed to load products"
        }
        isLoading = false
    }
    
    func purchase(_ product: IAPProduct) async {
        purchaseInProgress = true
        message = nil
        
        do {
            let transaction = try await IAPManager.shared.purchase(
                productId: product.id
            )
            message = "Purchase successful!"
        } catch IAPError.userCancelled {
            message = "Purchase cancelled"
        } catch {
            message = "Purchase failed: \(error.localizedDescription)"
        }
        
        purchaseInProgress = false
    }
    
    func restore() async {
        purchaseInProgress = true
        message = nil
        
        do {
            let restored = try await IAPManager.shared.restorePurchases()
            message = "Restored \(restored.count) purchase(s)"
        } catch {
            message = "Restore failed"
        }
        
        purchaseInProgress = false
    }
}

struct ProductRow: View {
    let product: IAPProduct
    let onPurchase: () async -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.displayName)
                    .font(.headline)
                Text(product.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                Task { await onPurchase() }
            }) {
                Text(product.displayPrice)
                    .bold()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 4)
    }
}
```

## Error Handling

Always handle errors appropriately:

```swift
do {
    let transaction = try await IAPManager.shared.purchase(productId: productId)
    // Handle successful purchase
} catch IAPError.userCancelled {
    // User cancelled - no action needed
} catch IAPError.productNotFound {
    // Show "Product not available" message
} catch IAPError.purchaseNotAllowed {
    // Show "Purchases are disabled" message
} catch IAPError.networkError {
    // Show "Network error, please try again" message
} catch {
    // Handle other errors
    print("Unexpected error: \(error)")
}
```

## Next Steps

- Learn about [IAPManager](IAPManager) in detail
- Explore [Transaction Verification](Transaction-Verification)
- Implement [Testing](Testing) with mock objects
- Read [Best Practices](Best-Practices)
