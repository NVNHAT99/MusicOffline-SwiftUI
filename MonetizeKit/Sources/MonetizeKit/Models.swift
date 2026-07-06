import Foundation
import StoreKit

// MARK: - IAP Error Types
/// Errors that can occur during In-App Purchase operations
public enum IAPError: Error, LocalizedError, Equatable {
    case productNotFound(String)
    case purchaseFailed(String)
    case purchaseCancelled
    case verificationFailed(String)
    case transactionNotFound(String)
    case networkError
    case unknownError(String)
    case storeKitError(Error)
    case receiptNotFound
    case receiptReadFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .productNotFound(let productId):
            return "Product not found: \(productId)"
        case .purchaseFailed(let reason):
            return "Purchase failed: \(reason)"
        case .purchaseCancelled:
            return "Purchase was cancelled by user"
        case .verificationFailed(let reason):
            return "Transaction verification failed: \(reason)"
        case .transactionNotFound(let transactionId):
            return "Transaction not found: \(transactionId)"
        case .networkError:
            return "Network error occurred"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        case .storeKitError(let error):
            return "StoreKit error: \(error.localizedDescription)"
        case .receiptNotFound:
            return "App Store receipt not found"
        case .receiptReadFailed(let reason):
            return "Failed to read receipt: \(reason)"
        }
    }
    
    public static func == (lhs: IAPError, rhs: IAPError) -> Bool {
        switch (lhs, rhs) {
        case (.productNotFound(let lhsId), .productNotFound(let rhsId)):
            return lhsId == rhsId
        case (.purchaseFailed(let lhsReason), .purchaseFailed(let rhsReason)):
            return lhsReason == rhsReason
        case (.purchaseCancelled, .purchaseCancelled):
            return true
        case (.verificationFailed(let lhsReason), .verificationFailed(let rhsReason)):
            return lhsReason == rhsReason
        case (.transactionNotFound(let lhsId), .transactionNotFound(let rhsId)):
            return lhsId == rhsId
        case (.networkError, .networkError):
            return true
        case (.unknownError(let lhsMsg), .unknownError(let rhsMsg)):
            return lhsMsg == rhsMsg
        case (.receiptNotFound, .receiptNotFound):
            return true
        case (.receiptReadFailed(let lhsReason), .receiptReadFailed(let rhsReason)):
            return lhsReason == rhsReason
        default:
            return false
        }
    }
}

// MARK: - Entitlement
/// Represents a user's entitlement to a product or service
public struct Entitlement: Hashable, Sendable {
    /// The product identifier for this entitlement
    public let productId: String
    
    /// Whether the user currently has access to this entitlement
    public let isActive: Bool
    
    /// The date when this entitlement was first granted
    public let purchaseDate: Date?
    
    /// The expiration date for subscription-based entitlements (nil for non-consumables)
    public let expirationDate: Date?
    
    /// The original transaction ID for this entitlement
    public let originalTransactionId: String?
    
    /// Whether this is a subscription-based entitlement
    public var isSubscription: Bool {
        expirationDate != nil
    }
    
    /// Whether this entitlement has expired (only relevant for subscriptions)
    public var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        return Date() > expirationDate
    }
    
    public init(
        productId: String,
        isActive: Bool,
        purchaseDate: Date? = nil,
        expirationDate: Date? = nil,
        originalTransactionId: String? = nil
    ) {
        self.productId = productId
        self.isActive = isActive
        self.purchaseDate = purchaseDate
        self.expirationDate = expirationDate
        self.originalTransactionId = originalTransactionId
    }
}

// MARK: - IAP Product
/// A simplified representation of a StoreKit Product with additional metadata
public struct IAPProduct: Hashable, Sendable {
    /// The product identifier
    public let id: String
    
    /// The display name of the product
    public let displayName: String
    
    /// The product description
    public let description: String
    
    /// The formatted price string (e.g., "$9.99")
    public let displayPrice: String
    
    /// The raw price value
    public let price: Decimal
    
    /// The product type
    public let type: ProductType
    
    /// The subscription information (nil for non-subscription products)
    public let subscriptionInfo: SubscriptionInfo?
    
    public init(
        id: String,
        displayName: String,
        description: String,
        displayPrice: String,
        price: Decimal,
        type: ProductType,
        subscriptionInfo: SubscriptionInfo? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.displayPrice = displayPrice
        self.price = price
        self.type = type
        self.subscriptionInfo = subscriptionInfo
    }
    
    /// Convenience initializer from StoreKit Product
    public init(from product: Product) {
        self.id = product.id
        self.displayName = product.displayName
        self.description = product.description
        self.displayPrice = product.displayPrice
        self.price = product.price
        
        switch product.type {
        case .consumable:
            self.type = .consumable
        case .nonConsumable:
            self.type = .nonConsumable
        case .autoRenewable:
            self.type = .autoRenewableSubscription
        case .nonRenewable:
            self.type = .nonRenewableSubscription
        default:
            self.type = .unknown
        }
        
        if let subscription = product.subscription {
            self.subscriptionInfo = SubscriptionInfo(
                groupId: subscription.subscriptionGroupID,
                period: subscription.subscriptionPeriod.debugDescription
            )
        } else {
            self.subscriptionInfo = nil
        }
    }
}

// MARK: - Product Type
/// The type of in-app purchase product
public enum ProductType: String, CaseIterable, Sendable {
    case consumable
    case nonConsumable
    case autoRenewableSubscription
    case nonRenewableSubscription
    case unknown
}

// MARK: - Subscription Info
/// Additional information for subscription products
public struct SubscriptionInfo: Hashable, Sendable {
    /// The subscription group identifier
    public let groupId: String
    
    /// The subscription period description (e.g., "P1M" for monthly)
    public let period: String
    
    public init(groupId: String, period: String) {
        self.groupId = groupId
        self.period = period
    }
}