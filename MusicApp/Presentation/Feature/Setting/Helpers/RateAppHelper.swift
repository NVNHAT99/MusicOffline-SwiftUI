//
//  RateAppHelper.swift
//  MusicApp
//

import StoreKit

enum RateAppHelper {
    static func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return }
        SKStoreReviewController.requestReview(in: scene)
    }
}
