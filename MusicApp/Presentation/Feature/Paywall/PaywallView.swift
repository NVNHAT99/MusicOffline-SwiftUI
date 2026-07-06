//
//  PaywallView.swift
//  MusicApp
//
//  Full-screen "Remove Ads" paywall. Simple @State-based flow (KISS — no full MVI
//  since this screen has no shared state with the rest of the app).
//  Presented via AppRoute.paywall (fullScreen).
//

import SwiftUI
import MonetizeKit

// MARK: - PaywallView

struct PaywallView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var product: IAPProduct?
    @State private var isLoadingProducts = true
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?
    @State private var purchaseSucceeded = false

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.backgroundColor.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: DesignToken.Spacing.lg) {
                    heroSection
                    featuresSection
                    priceSection
                    purchaseButton
                    restoreButton
                    footerSection
                }
                .padding(.horizontal, DesignToken.Spacing.lg)
                .padding(.top, DesignToken.Spacing.xxl + DesignToken.Spacing.md)
                .padding(.bottom, DesignToken.Spacing.xxl)
            }

            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.mutedText)
            }
            .padding(.top, DesignToken.Spacing.xl)
            .padding(.trailing, DesignToken.Spacing.lg)
        }
        .task { await loadProducts() }
        .onChange(of: purchaseSucceeded) { _, succeeded in
            if succeeded { dismiss() }
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            ),
            actions: { Button("OK") { errorMessage = nil } },
            message: { Text(errorMessage ?? "") }
        )
    }

    // MARK: - Sections

    private var heroSection: some View {
        VStack(spacing: DesignToken.Spacing.md) {
            // App icon placeholder (music note)
            ZStack {
                RoundedRectangle(cornerRadius: DesignToken.Radius.lg)
                    .fill(Color.accentPrimary.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "music.note")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.accentPrimary)
            }

            Text("MusicOffline Premium")
                .font(AppFont.title())
                .foregroundColor(.primaryText)
                .multilineTextAlignment(.center)

            Text("Remove all ads and support development")
                .font(AppFont.callout())
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var featuresSection: some View {
        VStack(spacing: DesignToken.Spacing.sm) {
            featureRow(icon: "xmark.circle.fill", text: "No banner or interstitial ads")
            featureRow(icon: "heart.fill", text: "Support indie development")
            featureRow(icon: "infinity", text: "Lifetime access — pay once")
            featureRow(icon: "lock.open.fill", text: "Unlocked forever, even offline")
        }
        .padding(DesignToken.Spacing.md)
        .background(Color.headerBackground)
        .cornerRadius(DesignToken.Radius.md)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: DesignToken.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.accentPrimary)
                .frame(width: 24)
            Text(text)
                .font(AppFont.body())
                .foregroundColor(.primaryText)
            Spacer()
        }
    }

    @ViewBuilder
    private var priceSection: some View {
        if isLoadingProducts {
            ProgressView()
                .frame(height: 90)
                .frame(maxWidth: .infinity)
        } else if let product {
            VStack(spacing: DesignToken.Spacing.xs) {
                Text(product.displayPrice)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundColor(.primaryText)
                Text("One-time purchase · Lifetime access")
                    .font(AppFont.caption())
                    .foregroundColor(.mutedText)
            }
            .frame(maxWidth: .infinity)
            .padding(DesignToken.Spacing.md)
            .background(Color.headerBackground)
            .cornerRadius(DesignToken.Radius.md)
        } else {
            Text("Unable to load product.\nPlease check your connection.")
                .font(AppFont.caption())
                .foregroundColor(.mutedText)
                .multilineTextAlignment(.center)
                .frame(height: 90)
                .frame(maxWidth: .infinity)
        }
    }

    private var purchaseButton: some View {
        Button(action: { Task { await performPurchase() } }) {
            Group {
                if isPurchasing {
                    ProgressView()
                        .tint(Color.white)
                } else {
                    Text("Unlock Lifetime")
                        .font(AppFont.headline())
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                (product != nil && !isPurchasing)
                    ? Color.accentPrimary
                    : Color.accentPrimary.opacity(0.4)
            )
            .cornerRadius(DesignToken.Radius.full)
        }
        .disabled(product == nil || isPurchasing || isRestoring)
        .buttonStyle(.plain)
    }

    private var restoreButton: some View {
        Button(action: { Task { await performRestore() } }) {
            if isRestoring {
                ProgressView().scaleEffect(0.8)
            } else {
                Text("Restore Purchases")
                    .font(AppFont.callout())
                    .foregroundColor(.secondaryText)
                    .underline()
            }
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing || isRestoring)
    }

    private var footerSection: some View {
        VStack(spacing: DesignToken.Spacing.xs) {
            HStack(spacing: DesignToken.Spacing.md) {
                Link("Privacy Policy", destination: URL(string: "https://sites.google.com/view/musicoffline-privacy")!)
                Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            }
            .font(AppFont.caption())
            .foregroundColor(.mutedText)

            Text("Payment will be charged to your Apple ID. The purchase is non-refundable.")
                .font(.system(.caption2))
                .foregroundColor(.mutedText)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Actions

    private func loadProducts() async {
        isLoadingProducts = true
        let products = await IAPService.shared.loadProducts()
        product = products.first
        isLoadingProducts = false
    }

    private func performPurchase() async {
        guard !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let success = try await IAPService.shared.purchase()
            if success { purchaseSucceeded = true }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func performRestore() async {
        guard !isRestoring else { return }
        isRestoring = true
        defer { isRestoring = false }

        let restored = await IAPService.shared.restore()
        if restored {
            purchaseSucceeded = true
        } else {
            errorMessage = "No previous purchase found for this Apple ID."
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}
