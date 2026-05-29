//
//  SetupTimerSheetView.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 9/1/25.
//

import SwiftUI

struct SetupTimerSheetView: View {
    @ObservedObject var viewModel: TimerMenuViewModel

    init(viewModel: TimerMenuViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {

            Button {
                viewModel.navigateToPicker()
            } label: {
                Text("Set Sleep Time")
                    .font(AppFont.body())
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .foregroundColor(.primaryText)
            .buttonStyle(.pressScale)

            Divider()
                .background(Color.separator)

            Button {
                viewModel.cancelSleepTime()
            } label: {
                Text("Cancel Sleep Time")
                    .font(AppFont.body())
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .foregroundColor(.primaryText)
            .buttonStyle(.pressScale)
        }
        .presentationDetents([.height(120)])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(false)
        .presentationBackground(Color.backgroundColor)
    }
}

#Preview {
    let viewModel = TimerMenuViewModel()
    return SetupTimerSheetView(viewModel: viewModel)
}
