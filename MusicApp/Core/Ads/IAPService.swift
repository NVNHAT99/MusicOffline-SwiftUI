//
//  IAPService.swift
//  MusicApp
//
//  Single-class IAP adapter over MonetizeKit for the lifetime "Remove Ads" purchase.
//  Syncs entitlement to AppState so the rest of the app just reads `AppState.shared.isPremium`.
//

import Foundation
import MonetizeKit

// MARK: - IAPService

@MainActor
final class IAPService {

    // MARK: - Singleton

    static let shared = IAPService()

    // MARK: - Private

    private let manager: IAPManager

    private init(manager: IAPManager = .shared) {
        self.manager = manager
    }

    // MARK: - Public API

    /// Call once at app startup. Configures MonetizeKit and syncs the persisted
    /// entitlement so `AppState.shared.isPremium` is correct before first render.
    func configure() async {
        do {
            try await manager.configure(productIds: AppProductId.all)
        } catch {
            Logger.warning("IAPService.configure failed: \(error.localizedDescription)")
        }
        await syncEntitlement()
    }

    /// Fetch the lifetime product from StoreKit. Returns empty array on failure.
    func loadProducts() async -> [IAPProduct] {
        // Wait until configured (bounded: 5 s) to avoid racing cold-start.
        await waitUntilConfigured(timeout: 5.0)
        do {
            return try await manager.products()
        } catch {
            Logger.warning("IAPService.loadProducts failed: \(error.localizedDescription)")
            return []
        }
    }

    /// Purchase the lifetime product.
    /// - Returns: `true` on success; `false` on user cancellation.
    /// - Throws: rethrows non-cancellation errors for the UI to display.
    func purchase() async throws -> Bool {
        await waitUntilConfigured(timeout: 5.0)

        do {
            let transaction = try await manager.purchase(productId: AppProductId.lifetime)
            await manager.finishTransaction(transaction)
            await syncEntitlement()
            return AppState.shared.isPremium
        } catch let iapError as IAPError {
            if case .purchaseCancelled = iapError {
                // User tapped Cancel — not an error we surface.
                return false
            }
            throw iapError
        }
    }

    /// Restore previous purchases.
    /// - Returns: `true` if the lifetime entitlement is now active.
    func restore() async -> Bool {
        await waitUntilConfigured(timeout: 5.0)

        do {
            let transactions = try await manager.restorePurchases()
            for tx in transactions {
                await manager.finishTransaction(tx)
            }
        } catch {
            Logger.warning("IAPService.restore failed: \(error.localizedDescription)")
        }

        await syncEntitlement()
        return AppState.shared.isPremium
    }

    /// Re-read the StoreKit entitlement and push the result to AppState.
    func syncEntitlement() async {
        let active = await manager.hasActiveEntitlement(for: AppProductId.lifetime)
        AppState.shared.setPremium(active)
    }

    // MARK: - Private Helpers

    /// Polls `IAPManager.isConfigured()` for up to `timeout` seconds.
    private func waitUntilConfigured(timeout: TimeInterval) async {
        let deadline = Date().addingTimeInterval(timeout)
        while await !manager.isConfigured(), Date() < deadline {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100 ms
        }
    }
}
