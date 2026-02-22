//
//  TimerPickerView.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 9/1/25.
//

import SwiftUI

typealias TimerPickerSaveAction = @Sendable (Double, Double, Double) -> Void

struct TimerPickerView: View {
    @StateObject private var viewModel: TimerPickerViewModel

    init(viewModel: TimerPickerViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack {
            CustomNavigationBar(type: .backButton(title: nil, tintColor: .white,
                                                  action: {
                Task { @MainActor in
                    viewModel.back()
                }
            }))
            Spacer()
            HStack(spacing: 0) {

                Picker("hours", selection: $viewModel.hours) {
                    ForEach(0..<24, id: \.self) {
                        Text("\($0)")
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 80)
                .clipped()

                Text("Hours")

                Picker("minus", selection: $viewModel.minutes) {
                    ForEach(0..<60, id: \.self) {
                        Text("\($0)")
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 80)
                .clipped()

                Text("Mins")


                Picker("Second", selection: $viewModel.seconds) {
                    ForEach(0..<60, id: \.self) {
                        Text("\($0)")
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 80)
                .clipped()


                Text("Secs")
            }
            .frame(maxWidth: .infinity)
            .pickerStyle(.wheel)
            .foregroundStyle(.white)
            .padding(.bottom, 16)

            Button {
                viewModel.save()
            } label: {
                Text("Save")
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.headerBackground)
                    .cornerRadius(8, corners: .allCorners)
            }
            Spacer()
        }
        .background(Color.backgroundColor)
    }
}



#Preview {
    let viewModel = TimerPickerViewModel()
    viewModel.onBack = {}
    viewModel.onSave = { _, _, _ in }
    return TimerPickerView(viewModel: viewModel)
        .background(Color.backgroundColor)
}
