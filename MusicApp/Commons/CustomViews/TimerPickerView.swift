//
//  TimerPickerView.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 9/1/25.
//

import SwiftUI

typealias TimerPickerSaveAction = @Sendable (Double, Double, Double) -> Void

struct TimerPickerView: View {
    @State var hour: Int = 0
    @State var minute: Int = 0
    @State var second: Int = 0
    
    let saveAction: @Sendable (Double, Double, Double) -> Void
    let backAction: @Sendable () -> Void
    var body: some View {
        
        VStack {
            CustomNavigationBar(type: .backButton(title: nil, tintColor: .white,
                                                  action: {
                backAction()
            }))
            Spacer()
            HStack(spacing: 0) {
                
                Picker("hours", selection: $hour) {
                    ForEach(0..<24, id: \.self) {
                        Text("\($0)")
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 80)
                .clipped()
                
                Text("Hours")
                
                Picker("minus", selection: $minute) {
                    ForEach(0..<60, id: \.self) {
                        Text("\($0)")
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 80)
                .clipped()
                
                Text("Mins")
                
                
                Picker("Second", selection: $second) {
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
                saveAction(Double(hour), Double(minute), Double(second))
                backAction()
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
    TimerPickerView(saveAction: {_,_,_ in }, backAction: {})
        .background(Color.backgroundColor)
}
