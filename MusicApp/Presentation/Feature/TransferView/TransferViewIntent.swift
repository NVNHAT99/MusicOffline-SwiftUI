//
//  TransferViewIntent.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/1/25.
//

import Foundation

enum TransferViewIntent {
    case toggleServer
    case handleBackAction(Router<AppRoute>)
    case copyIPAdress
}
