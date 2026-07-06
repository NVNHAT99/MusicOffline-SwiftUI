import Foundation
import StoreKit

/// Mock implementation of PurchasesProtocol for testing
/// 
/// This mock allows you to simulate various purchase scenarios:
/// - Successful purchases
/// - Failed purchases
/// - Cancelled purchases
/// - Transaction updates
/// - Entitlement changes
///
/// ## Usage Example
/// ```swift
/// let mockPurchases = MockPurchases()
/// mockPurchases.mockEntitlements = [
///     Entitlement(productId: "premium", isActive: true)
/// ]
/// 
/// let iapManager = IAPManager(purchases: mockPurchases)
/// ```
public actor MockPurchases: PurchasesProtocol {
    
    // MARK: - Mock Configuration
    
    /// Entitlements to return and stream
    public var mockEntitlements: [Entitlement] = [] {
        didSet {
            entitlementsContinuation.yield(mockEntitlements)
        }
    }
    
    /// Error to throw during purchase (if set)
    public var purchaseError: IAPError?
    
    /// Error to throw during restore (if set)
    public var restoreError: IAPError?
    
    /// Mock pending transactions
    public var mockPendingTransactions: [MockTransaction] = []
    
    /// Mock restored transactions (returned by restorePurchases)
    public var mockRestoredTransactions: [MockTransaction] = []
    
    /// Whether to simulate a cancelled purchase
    public var shouldCancelPurchase: Bool = false
    
    /// Simulated delay for operations in seconds
    public var simulatedDelay: TimeInterval = 0
    
    // MARK: - State Tracking
    
    private var isObservingTransactions = false
    private var purchaseCallCount = 0
    private var restoreCallCount = 0
    private var finishedTransactions: [UInt64] = []
    
    // Entitlements stream
    private let entitlementsContinuation: AsyncStream<[Entitlement]>.Continuation
    nonisolated public let entitlementsStream: AsyncStream<[Entitlement]>
    
    public init() {
        let (stream, continuation) = AsyncStream.makeStream(of: [Entitlement].self)
        self.entitlementsStream = stream
        self.entitlementsContinuation = continuation
    }
    
    deinit {
        entitlementsContinuation.finish()
    }
    
    // MARK: - PurchasesProtocol Implementation
    
    public func startObservingTransactions() async {
        isObservingTransactions = true
    }
    
    public func stopObservingTransactions() async {
        isObservingTransactions = false
    }
    
    public func purchase(_ product: IAPProduct) async throws -> TransactionProtocol {
        purchaseCallCount += 1
        
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }
        
        if shouldCancelPurchase {
            throw IAPError.purchaseCancelled
        }
        
        if let error = purchaseError {
            throw error
        }
        
        // Create a mock transaction
        let mockTransaction = MockTransaction(
            id: UInt64.random(in: 1...UInt64.max),
            originalID: UInt64.random(in: 1...UInt64.max),
            productID: product.id,
            purchaseDate: Date(),
            expirationDate: product.type == .autoRenewableSubscription ? Date().addingTimeInterval(2592000) : nil // 30 days for subscriptions
        )
        
        // Update entitlements
        let entitlement = Entitlement(
            productId: product.id,
            isActive: true,
            purchaseDate: mockTransaction.purchaseDate,
            expirationDate: mockTransaction.expirationDate,
            originalTransactionId: String(mockTransaction.originalID)
        )
        
        var updatedEntitlements = mockEntitlements.filter { $0.productId != product.id }
        updatedEntitlements.append(entitlement)
        mockEntitlements = updatedEntitlements
        
        return mockTransaction
    }
    
    public func restorePurchases() async throws -> [TransactionProtocol] {
        restoreCallCount += 1
        
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }
        
        if let error = restoreError {
            throw error
        }
        
        return mockRestoredTransactions
    }
    
    public func getPendingTransactions() async -> [TransactionProtocol] {
        return mockPendingTransactions.filter { !finishedTransactions.contains($0.id) }
    }
    
    public func finishTransaction(_ transaction: TransactionProtocol) async {
        finishedTransactions.append(transaction.id)
    }
    
    // MARK: - Mock-Specific Methods
    
    /// Get current entitlements synchronously
    public func getCurrentEntitlements() async -> [Entitlement] {
        return mockEntitlements
    }
    
    /// Check if user has active entitlement for a specific product
    public func hasActiveEntitlement(for productId: String) async -> Bool {
        return mockEntitlements.first { $0.productId == productId }?.isActive == true
    }
    
    /// Get entitlement for a specific product
    public func getEntitlement(for productId: String) async -> Entitlement? {
        return mockEntitlements.first { $0.productId == productId }
    }

    /// Get first active entitlement (mock: checks isActive flag, no real refresh)
    public func getActiveEntitlementWithRefresh() async -> Entitlement? {
        return mockEntitlements.first { $0.isActive && !$0.isExpired }
    }

    /// Refresh the App Store receipt (mock implementation)
    public func refreshReceipt() async throws {
        if simulatedDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))
        }
        // Mock implementation - just succeed without doing anything
    }

    /// Check if currently observing transactions
    public func getIsObservingTransactions() async -> Bool {
        return isObservingTransactions
    }
    
    /// Get the number of purchase attempts
    public func getPurchaseCallCount() async -> Int {
        return purchaseCallCount
    }
    
    /// Get the number of restore attempts
    public func getRestoreCallCount() async -> Int {
        return restoreCallCount
    }
    
    /// Get finished transaction IDs
    public func getFinishedTransactions() async -> [UInt64] {
        return finishedTransactions
    }
    
    /// Reset all mock state
    public func reset() async {
        mockEntitlements.removeAll()
        purchaseError = nil
        restoreError = nil
        mockPendingTransactions.removeAll()
        mockRestoredTransactions.removeAll()
        shouldCancelPurchase = false
        simulatedDelay = 0
        isObservingTransactions = false
        purchaseCallCount = 0
        restoreCallCount = 0
        finishedTransactions.removeAll()
    }
    
    /// Add a mock entitlement
    public func addMockEntitlement(_ entitlement: Entitlement) async {
        var updated = mockEntitlements.filter { $0.productId != entitlement.productId }
        updated.append(entitlement)
        mockEntitlements = updated
    }
    
    /// Remove a mock entitlement
    public func removeMockEntitlement(productId: String) async {
        mockEntitlements.removeAll { $0.productId == productId }
    }
    
    /// Add a pending transaction
    public func addPendingTransaction(_ transaction: MockTransaction) async {
        mockPendingTransactions.append(transaction)
    }
    
    /// Simulate a transaction update (useful for testing observers)
    public func simulateTransactionUpdate() async {
        // This would trigger the entitlements stream
        entitlementsContinuation.yield(mockEntitlements)
    }
    
    /// Set up common test scenarios
    public func setupSuccessfulPurchase() async {
        purchaseError = nil
        shouldCancelPurchase = false
    }
    
    public func setupCancelledPurchase() async {
        shouldCancelPurchase = true
    }
    
    public func setupFailedPurchase(error: IAPError) async {
        purchaseError = error
    }
    
    public func setupActiveSubscription(productId: String) async {
        let entitlement = Entitlement(
            productId: productId,
            isActive: true,
            purchaseDate: Date(),
            expirationDate: Date().addingTimeInterval(2592000), // 30 days
            originalTransactionId: "mock_\(productId)"
        )
        await addMockEntitlement(entitlement)
    }
    
    public func setupExpiredSubscription(productId: String) async {
        let entitlement = Entitlement(
            productId: productId,
            isActive: false,
            purchaseDate: Date().addingTimeInterval(-3600), // 1 hour ago
            expirationDate: Date().addingTimeInterval(-60), // 1 minute ago
            originalTransactionId: "mock_\(productId)"
        )
        await addMockEntitlement(entitlement)
    }
}

// MARK: - Mock Transaction

/// A mock implementation of Transaction for testing
public struct MockTransaction: TransactionProtocol {
    public let id: UInt64
    public let originalID: UInt64
    public let productID: String
    public let purchaseDate: Date
    public let expirationDate: Date?
    public let revocationDate: Date?
    public let isUpgraded: Bool
    
    public init(
        id: UInt64,
        originalID: UInt64,
        productID: String,
        purchaseDate: Date,
        expirationDate: Date? = nil,
        revocationDate: Date? = nil,
        isUpgraded: Bool = false
    ) {
        self.id = id
        self.originalID = originalID
        self.productID = productID
        self.purchaseDate = purchaseDate
        self.expirationDate = expirationDate
        self.revocationDate = revocationDate
        self.isUpgraded = isUpgraded
    }
    
    public func finish() async {
        // Mock implementation - no-op
    }
}

// MARK: - Mock Verification

/// A mock verifier that can be configured to pass or fail verification
public struct MockVerifier: VerificationProtocol {
    public let shouldPassVerification: Bool
    
    public init(shouldPassVerification: Bool = true) {
        self.shouldPassVerification = shouldPassVerification
    }
    
    public func verify(transaction: TransactionProtocol) async throws -> Bool {
        if shouldPassVerification {
            return true
        } else {
            throw IAPError.verificationFailed("Mock verification failed")
        }
    }
    
    public func verifyJWS(_ jwsRepresentation: String) async throws -> Bool {
        if shouldPassVerification {
            return true
        } else {
            throw IAPError.verificationFailed("Mock JWS verification failed")
        }
    }
}