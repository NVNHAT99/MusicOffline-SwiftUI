import Foundation
import StoreKit

// MARK: - Transaction Protocol Conformance

extension Transaction: TransactionProtocol {
    // Transaction already has all the required properties and methods
    // No additional implementation needed
}

// MARK: - Transaction Extensions

extension Transaction {
    
    /// Helper property to safely get the product ID
    /// 
    /// This provides a fallback mechanism for accessing the product ID
    /// in case of any StoreKit API changes or edge cases.
    public var safeProductID: String {
        return productID
    }
    
    /// Check if this transaction represents an active subscription
    /// 
    /// A subscription is considered active if:
    /// - It has an expiration date in the future, OR
    /// - It's a non-renewable subscription without expiration, OR
    /// - It hasn't been revoked
    ///
    /// - Returns: True if the subscription is currently active
    public var isActiveSubscription: Bool {
        // Check if transaction has been revoked
        if revocationDate != nil {
            return false
        }
        
        // For transactions with expiration dates (auto-renewable subscriptions)
        if let expirationDate = expirationDate {
            return Date() < expirationDate
        }
        
        // For non-expiring transactions (non-renewable subscriptions, non-consumables)
        // Consider them active if not revoked
        return true
    }
    
    /// Check if this transaction has expired
    /// 
    /// Only relevant for subscription transactions with expiration dates.
    ///
    /// - Returns: True if the transaction has expired, false otherwise
    public var isExpired: Bool {
        guard let expirationDate = expirationDate else {
            return false // Non-expiring transactions are never "expired"
        }
        return Date() > expirationDate
    }
    
    /// Get the duration until expiration
    /// 
    /// - Returns: TimeInterval until expiration, or nil if no expiration date
    public var timeUntilExpiration: TimeInterval? {
        guard let expirationDate = expirationDate else {
            return nil
        }
        let timeInterval = expirationDate.timeIntervalSince(Date())
        return timeInterval > 0 ? timeInterval : 0
    }
    
    /// Get the time since purchase
    /// 
    /// - Returns: TimeInterval since the purchase date
    public var timeSincePurchase: TimeInterval {
        return Date().timeIntervalSince(purchaseDate)
    }
    
    /// Check if this is a restored transaction
    /// 
    /// A transaction is considered restored if its transaction ID differs
    /// from its original transaction ID.
    ///
    /// - Returns: True if this is a restored transaction
    public var isRestored: Bool {
        return id != originalID
    }
    
    /// Get a user-friendly description of the transaction state
    /// 
    /// - Returns: String describing the current state of the transaction
    public var stateDescription: String {
        if let revocationDate = revocationDate {
            return "Revoked on \(DateFormatter.userFriendly.string(from: revocationDate))"
        }
        
        if let expirationDate = expirationDate {
            if isExpired {
                return "Expired on \(DateFormatter.userFriendly.string(from: expirationDate))"
            } else {
                return "Active until \(DateFormatter.userFriendly.string(from: expirationDate))"
            }
        }
        
        return "Active"
    }
    
    /// Check if this transaction is eligible for a refund
    /// 
    /// This is a simplified check based on purchase date.
    /// Actual refund eligibility depends on Apple's policies and other factors.
    ///
    /// - Returns: True if the transaction might be eligible for a refund
    public var mightBeEligibleForRefund: Bool {
        // Simple heuristic: transactions within the last 90 days might be eligible
        let ninetyDaysAgo = Date().addingTimeInterval(-90 * 24 * 60 * 60)
        return purchaseDate > ninetyDaysAgo && revocationDate == nil
    }
}

// MARK: - Product Extensions

extension Product {
    
    /// Get a user-friendly subscription period description
    /// 
    /// - Returns: String describing the subscription period, or nil for non-subscriptions
    public var subscriptionPeriodDescription: String? {
        guard let subscription = subscription else { return nil }
        
        let period = subscription.subscriptionPeriod
        let unit: String
        let value = period.value
        
        switch period.unit {
        case .day:
            unit = value == 1 ? "day" : "days"
        case .week:
            unit = value == 1 ? "week" : "weeks"
        case .month:
            unit = value == 1 ? "month" : "months"
        case .year:
            unit = value == 1 ? "year" : "years"
        @unknown default:
            unit = "period"
        }
        
        if value == 1 {
            return "Every \(unit)"
        } else {
            return "Every \(value) \(unit)"
        }
    }
    
    /// Get the subscription period in days (approximate)
    /// 
    /// - Returns: Number of days in the subscription period, or nil for non-subscriptions
    public var subscriptionPeriodInDays: Int? {
        guard let subscription = subscription else { return nil }
        
        let period = subscription.subscriptionPeriod
        let value = period.value
        
        switch period.unit {
        case .day:
            return value
        case .week:
            return value * 7
        case .month:
            return value * 30 // Approximate
        case .year:
            return value * 365 // Approximate
        @unknown default:
            return nil
        }
    }
    
    /// Check if this is a subscription product
    /// 
    /// - Returns: True if this is any type of subscription
    public var isSubscription: Bool {
        return type == .autoRenewable || type == .nonRenewable
    }
    
    /// Get the product type as a user-friendly string
    /// 
    /// - Returns: String description of the product type
    public var typeDescription: String {
        switch type {
        case .consumable:
            return "Consumable"
        case .nonConsumable:
            return "Non-Consumable"
        case .autoRenewable:
            return "Auto-Renewable Subscription"
        case .nonRenewable:
            return "Non-Renewable Subscription"
        default:
            return "Unknown"
        }
    }
}

// MARK: - DateFormatter Extensions

extension DateFormatter {
    
    /// User-friendly date formatter for transaction dates
    static let userFriendly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter
    }()
    
    /// ISO date formatter for API communication
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    /// Short date formatter for UI display
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter
    }()
}

// MARK: - VerificationResult Extensions

extension VerificationResult {
    
    /// Get the underlying payload regardless of verification status
    /// 
    /// This can be useful for logging or debugging purposes, but should
    /// never be used for business logic without proper verification.
    ///
    /// - Returns: The underlying payload
    public var payload: SignedType {
        switch self {
        case .verified(let payload):
            return payload
        case .unverified(let payload, _):
            return payload
        }
    }
    
    /// Check if the result is verified
    /// 
    /// - Returns: True if the result passed verification
    public var isVerified: Bool {
        switch self {
        case .verified:
            return true
        case .unverified:
            return false
        }
    }
    
    /// Get the verification error if unverified
    /// 
    /// - Returns: The verification error, or nil if verified
    public var verificationError: VerificationResult<SignedType>.VerificationError? {
        switch self {
        case .verified:
            return nil
        case .unverified(_, let error):
            return error
        }
    }
}

// MARK: - Product.SubscriptionInfo Extensions

extension Product.SubscriptionInfo {
    
    /// Get all subscription offers (introductory and promotional)
    /// 
    /// - Returns: Array of all available offers for this subscription
    public var allOffers: [Product.SubscriptionOffer] {
        var offers: [Product.SubscriptionOffer] = []
        
        if let introductoryOffer = introductoryOffer {
            offers.append(introductoryOffer)
        }
        
        offers.append(contentsOf: promotionalOffers)
        
        return offers
    }
    
    /// Check if this subscription has any offers available
    /// 
    /// - Returns: True if introductory or promotional offers are available
    public var hasOffers: Bool {
        return introductoryOffer != nil || !promotionalOffers.isEmpty
    }
}

// MARK: - AppStore Extensions

extension AppStore {
    
    /// Check if the device can make payments
    /// 
    /// - Returns: True if payments are allowed on this device
    public static var canMakePayments: Bool {
        return SKPaymentQueue.canMakePayments()
    }
}

// MARK: - Error Extensions

extension IAPError {
    
    /// Create an IAPError from a StoreKit error
    /// 
    /// - Parameter error: The original error
    /// - Returns: Corresponding IAPError
    public static func from(_ error: Error) -> IAPError {
        if let iapError = error as? IAPError {
            return iapError
        }
        
        if let storeKitError = error as? StoreKitError {
            switch storeKitError {
            case .userCancelled:
                return .purchaseCancelled
            case .networkError:
                return .networkError
            case .systemError:
                return .unknownError("System error occurred")
            case .notAvailableInStorefront:
                return .productNotFound("Product not available in current storefront")
            case .notEntitled:
                return .purchaseFailed("User not entitled to this product")
            case .unknown:
                return .unknownError("Unknown StoreKit error")
            @unknown default:
                return .storeKitError(storeKitError)
            }
        }
        
        return .storeKitError(error)
    }
}
