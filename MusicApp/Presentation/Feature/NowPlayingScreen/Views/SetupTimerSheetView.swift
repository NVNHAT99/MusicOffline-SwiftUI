//
//  SetupTimerSheetView.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 9/1/25.
//

import SwiftUI

struct SetupTimerSheetView: View {
    let cancelAction: @Sendable () -> Void
    let naviToTimerPicker: @Sendable () -> Void
    var body: some View {
        VStack(spacing: 0) {
            
            Button {
                naviToTimerPicker()
            } label: {
                Text("Set Sleep Time")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .foregroundColor(.white)

            Divider()

            Button {
                cancelAction()
            } label: {
                Text("Cancel Sleep Time")
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .foregroundColor(.white)
        }
        .presentationDetents([.height(120)])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(false)
        .presentationBackground(Color.backgroundColor)
    }
}

#Preview {
    SetupTimerSheetView(cancelAction: {}, naviToTimerPicker: {})
}
