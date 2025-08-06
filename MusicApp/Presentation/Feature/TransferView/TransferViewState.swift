//
//  TransferViewState.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/1/25.
//

import Foundation

struct TransferViewState {
    var ipAdress: String?
    var isServerOn: Bool = false
    var messageToastView: String = String.empty
    var isShowToastView: Bool = false
    var showLoading: Bool = false
    var isShowForceSaveDialog: Bool = false
}
