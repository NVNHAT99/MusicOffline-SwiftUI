# Models

MonetizeKit provides comprehensive data models for handling In-App Purchase operations. All models are designed to be Sendable for safe concurrent access.

## IAPProduct

Represents an In-App Purchase product with all its metadata.

```swift
public struct IAPProduct: Identifiable, Sendable, Equatable
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | Product identifier |
| `type` | `ProductType` | Type of product (consumable, non-consumable, etc.) |
| `displayName` | `String` | Localized display name |
| `description` | `String` | Localized description |
| `price` | `Decimal` | Price as decimal value |
| `displayPrice` | `String` | Formatted price string |
| `currencyCode` | `String?` | ISO currency code |
| `subscription` | `SubscriptionInfo?` | Subscription details if applicable |
| `introductoryOffer` | `IntroductoryOffer?` | Intro offer details |
| `promotionalOffers` | `[PromotionalOffer]` | Available promotional offers |

### Example Usage

```swift
let product = IAPProduct(
    id: "com.app.premium",
    type: .nonConsumable,
    displayName: "Premium Upgrade",
    description: "Unlock all premium features",
    price: 9.99,
    displayPrice: "$9.99",
    currencyCode: "USD"
)

// Display in UI
Text(product.displayName)
Text(product.displayPrice)
```

## ProductType

Enum representing different IAP product types.

```swift
public enum ProductType: String, Sendable, CaseIterable {
    case consumable
    case nonConsumable
    case autoRenewableSubscription
    case nonRenewingSubscription
}
```

### Usage

```swift
switch product.type {
case .consumable:
    // Handle consumable (coins, gems, etc.)
case .nonConsumable:
    // Handle one-time purchase
case .autoRenewableSubscription:
    // Handle auto-renewing subscription
case .nonRenewingSubscription:
    // Handle non-renewing subscription
}
```

## IAPTransaction

Represents a completed or pending transaction.

```swift
public struct IAPTransaction: Identifiable, Sendable
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `UInt64` | Transaction identifier |
| `productId` | `String` | Associated product ID |
| `purchaseDate` | `Date` | Date of purchase |
| `originalPurchaseDate` | `Date?` | Original purchase date (for renewals) |
| `expirationDate` | `Date?` | Expiration date (subscriptions) |
| `transactionState` | `TransactionState` | Current state |
| `revocationDate` | `Date?` | Revocation date if revoked |
| `revocationReason` | `RevocationReason?` | Reason for revocation |
| `isUpgraded` | `Bool` | Whether upgraded to different subscription |
| `offerType` | `OfferType?` | Type of offer applied |
| `offerIdentifier` | `String?` | Promotional offer ID |

### TransactionState

```swift
public enum TransactionState: String, Sendable {
    case pending
    case purchased
    case failed
    case restored
    case deferred
}
```

### Example

```swift
// Check transaction state
if transaction.transactionState == .purchased {
    // Grant access to content
    await grantAccess(for: transaction.productId)
}

// Check if subscription is expired
if let expirationDate = transaction.expirationDate {
    if expirationDate > Date() {
        // Subscription is active
    }
}
```

## IAPEntitlement

Represents user's entitlement to a product.

```swift
public struct IAPEntitlement: Sendable
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `productId` | `String` | Product identifier |
| `isActive` | `Bool` | Whether entitlement is currently active |
| `expirationDate` | `Date?` | When entitlement expires |
| `purchaseDate` | `Date` | Original purchase date |
| `isInTrialPeriod` | `Bool` | Whether in free trial |
| `isInBillingRetryPeriod` | `Bool` | Whether in billing retry |
| `renewalState` | `RenewalState` | Subscription renewal state |
| `renewalInfo` | `RenewalInfo?` | Detailed renewal information |

### RenewalState

```swift
public enum RenewalState: String, Sendable {
    case subscribed
    case expired
    case inBillingRetryPeriod
    case inGracePeriod
    case revoked
}
```

### Example

```swift
if let entitlement = await IAPManager.shared.entitlement(for: "subscription") {
    if entitlement.isActive {
        if entitlement.isInTrialPeriod {
            showTrialBadge()
        }
        
        if let expirationDate = entitlement.expirationDate {
            showExpirationDate(expirationDate)
        }
    }
}
```

## SubscriptionInfo

Contains subscription-specific information.

```swift
public struct SubscriptionInfo: Sendable
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `subscriptionPeriod` | `SubscriptionPeriod` | Billing period |
| `subscriptionGroupID` | `String` | Subscription group identifier |
| `introductoryOffer` | `IntroductoryOffer?` | Intro offer details |
| `promotionalOffers` | `[PromotionalOffer]` | Available promo offers |
| `isFamilyShareable` | `Bool` | Can be shared with family |

### SubscriptionPeriod

```swift
public struct SubscriptionPeriod: Sendable {
    public let value: Int
    public let unit: PeriodUnit
    
    public enum PeriodUnit: String, Sendable {
        case day
        case week
        case month
        case year
    }
}
```

### Example

```swift
if let subscription = product.subscription {
    let period = subscription.subscriptionPeriod
    print("Billed every \(period.value) \(period.unit)")
    
    if subscription.isFamilyShareable {
        showFamilySharingBadge()
    }
}
```

## IntroductoryOffer

Represents an introductory offer for subscriptions.

```swift
public struct IntroductoryOffer: Sendable
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `price` | `Decimal` | Offer price |
| `displayPrice` | `String` | Formatted price string |
| `period` | `SubscriptionPeriod` | Offer duration |
| `numberOfPeriods` | `Int` | Number of periods |
| `paymentMode` | `PaymentMode` | How offer is charged |
| `type` | `OfferType` | Type of offer |

### PaymentMode

```swift
public enum PaymentMode: String, Sendable {
    case freeTrial
    case payAsYouGo
    case payUpFront
}
```

### OfferType

```swift
public enum OfferType: String, Sendable {
    case introductory
    case promotional
}
```

### Example

```swift
if let intro = product.introductoryOffer {
    switch intro.paymentMode {
    case .freeTrial:
        print("\(intro.period.value) \(intro.period.unit) free trial")
    case .payAsYouGo:
        print("\(intro.displayPrice) for \(intro.numberOfPeriods) periods")
    case .payUpFront:
        print("\(intro.displayPrice) for \(intro.period.value) \(intro.period.unit)")
    }
}
```

## IAPError

Comprehensive error type for IAP operations.

```swift
public enum IAPError: LocalizedError, Sendable
```

### Cases

| Case | Description |
|------|-------------|
| `configurationError` | MonetizeKit not properly configured |
| `productNotFound` | Product ID not found |
| `purchaseNotAllowed` | Purchases disabled on device |
| `purchaseFailed(Error?)` | Purchase failed with optional underlying error |
| `verificationFailed` | Transaction verification failed |
| `restoreFailed` | Restore purchases failed |
| `userCancelled` | User cancelled the purchase |
| `networkError` | Network connection issue |
| `unknown` | Unknown error occurred |

### Error Descriptions

```swift
extension IAPError {
    public var errorDescription: String? {
        switch self {
        case .configurationError:
            return "In-App Purchase is not configured properly"
        case .productNotFound:
            return "Product not found"
        case .purchaseNotAllowed:
            return "Purchases are not allowed on this device"
        case .purchaseFailed(let error):
            return "Purchase failed: \(error?.localizedDescription ?? "Unknown error")"
        case .verificationFailed:
            return "Transaction verification failed"
        case .restoreFailed:
            return "Failed to restore purchases"
        case .userCancelled:
            return "Purchase was cancelled"
        case .networkError:
            return "Network connection error"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
```

### Error Handling Example

```swift
do {
    let transaction = try await IAPManager.shared.purchase(productId: "premium")
} catch let error as IAPError {
    switch error {
    case .userCancelled:
        // Silent - user cancelled
        break
    case .purchaseNotAllowed:
        showAlert("Purchases are disabled. Check Settings > Screen Time > Content & Privacy Restrictions")
    case .networkError:
        showAlert("No network connection. Please try again.")
    case .productNotFound:
        showAlert("Product not available")
    default:
        showAlert(error.localizedDescription)
    }
}
```

## RevocationReason

Reasons why a transaction might be revoked.

```swift
public enum RevocationReason: Int, Sendable {
    case developerIssue = 0
    case other = 1
}
```

## RenewalInfo

Detailed renewal information for subscriptions.

```swift
public struct RenewalInfo: Sendable {
    public let willAutoRenew: Bool
    public let autoRenewPreference: String?
    public let expirationReason: ExpirationReason?
    public let isInBillingRetry: Bool
    public let gracePeriodExpirationDate: Date?
    public let priceIncreaseStatus: PriceIncreaseStatus?
}
```

### ExpirationReason

```swift
public enum ExpirationReason: Int, Sendable {
    case customerCancelled = 1
    case billingError = 2
    case customerDidNotConsentToPriceIncrease = 3
    case productNotAvailable = 4
    case other = 5
}
```

### PriceIncreaseStatus

```swift
public enum PriceIncreaseStatus: Int, Sendable {
    case customerHasNotResponded = 0
    case customerConsentedToIncrease = 1
}
```

## Usage Examples

### Complete Purchase Flow

```swift
// 1. Fetch product
guard let product = await IAPManager.shared.product(for: "premium") else {
    throw IAPError.productNotFound
}

// 2. Display product info
print("Product: \(product.displayName)")
print("Price: \(product.displayPrice)")

// 3. Purchase
let transaction = try await IAPManager.shared.purchase(product: product)

// 4. Check transaction
if transaction.transactionState == .purchased {
    // 5. Verify entitlement
    let entitlement = await IAPManager.shared.entitlement(for: product.id)
    
    if let entitlement = entitlement, entitlement.isActive {
        // Grant access
        unlockPremiumFeatures()
    }
}
```

### Subscription Status Check

```swift
func checkSubscriptionStatus(for productId: String) async -> String {
    guard let entitlement = await IAPManager.shared.entitlement(for: productId) else {
        return "Not Subscribed"
    }
    
    switch entitlement.renewalState {
    case .subscribed:
        if entitlement.isInTrialPeriod {
            return "Free Trial"
        }
        return "Active Subscription"
    case .expired:
        return "Expired"
    case .inBillingRetryPeriod:
        return "Payment Issue"
    case .inGracePeriod:
        return "Grace Period"
    case .revoked:
        return "Revoked"
    }
}
```

## Related Documentation

- [IAPManager](IAPManager) - Main manager class
- [Error-Types](Error-Types) - Detailed error handling
- [Protocols](Protocols) - Protocol definitions
