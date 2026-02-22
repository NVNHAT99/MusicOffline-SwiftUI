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
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .foregroundColor(.white)

            Divider()

            Button {
                viewModel.cancelSleepTime()
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
    let viewModel = TimerMenuViewModel()
    return SetupTimerSheetView(viewModel: viewModel)
}
