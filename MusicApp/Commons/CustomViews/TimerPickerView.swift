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
                            .foregroundColor(.primaryText)
                    }
                }
                .frame(width: 80)
                .clipped()

                Text("Hours")
                    .font(AppFont.body())
                    .foregroundColor(.secondaryText)

                Picker("minus", selection: $viewModel.minutes) {
                    ForEach(0..<60, id: \.self) {
                        Text("\($0)")
                            .foregroundColor(.primaryText)
                    }
                }
                .frame(width: 80)
                .clipped()

                Text("Mins")
                    .font(AppFont.body())
                    .foregroundColor(.secondaryText)

                Picker("Second", selection: $viewModel.seconds) {
                    ForEach(0..<60, id: \.self) {
                        Text("\($0)")
                            .foregroundColor(.primaryText)
                    }
                }
                .frame(width: 80)
                .clipped()

                Text("Secs")
                    .font(AppFont.body())
                    .foregroundColor(.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .pickerStyle(.wheel)
            .foregroundColor(.primaryText)
            .padding(.bottom, 16)

            Button {
                viewModel.save()
            } label: {
                Text("Save")
                    .font(AppFont.headline())
                    .foregroundColor(.primaryText)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.accentPrimary)
                    .cornerRadius(8, corners: .allCorners)
            }
            .buttonStyle(.pressScale)
            .sensoryFeedback(.success, trigger: viewModel.hours + viewModel.minutes + viewModel.seconds > 0)
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
