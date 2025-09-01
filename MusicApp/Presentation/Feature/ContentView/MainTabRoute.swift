//
//  NowPlayingRoute.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 9/1/25.
//

import SwiftUI

enum MainTabRoute: Routable {
    
    case setSleepTime(TimerPickerSaveAction)
    case showMenuBottomSheet(@Sendable () -> Void, @Sendable () -> Void)
    
    var presentationStyle: PresentationStyle {
        switch self {
        case .showMenuBottomSheet:
                .sheet
        case .setSleepTime:
                .fullScreen
        }
    }
    
    @ViewBuilder
    func view(attach router: any RouterHandling) -> some View {
        switch self {
        case .setSleepTime(let saveAction):
            TimerPickerView(saveAction: saveAction, backAction: {
                Task {
                    await MainActor.run {
                        router.dismiss()
                    }
                }
            })
        case .showMenuBottomSheet(let cancelAction, let naviSetTimer):
            SetupTimerSheetView(cancelAction: cancelAction, naviToTimerPicker: naviSetTimer)
        }
    }
}
