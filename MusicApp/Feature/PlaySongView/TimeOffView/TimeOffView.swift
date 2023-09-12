//
//  TimeOffView.swift
//  MusicApp
//
//  Created by Nhat on 9/10/23.
//

import SwiftUI

struct TimeOffView: View {
    @State var selected: Int = 1
    var didSelectdTime: (Int?) -> Void
    var body: some View {
        VStack(spacing: 16) {
            Picker("", selection: $selected) {
                ForEach(1...60, id: \.self) { index in
                    Text("\(index)").tag(index)
                        .foregroundColor(.white)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 200)
            .padding(16)
            .cornerRadius(8, corners: [.topLeft, .topRight])
            
            
            VStack(spacing: 16) {
                Button {
                    didSelectdTime(selected)
                } label: {
                    Text("OK")
                        .frame(width: 200, height: 36)
                        .foregroundColor(.white)
                        .background(Color.black.opacity(1))
                        .cornerRadius(4, corners: .allCorners)
                }
                Button {
                    didSelectdTime(nil)
                } label: {
                    Text("Cancel")
                        .frame(width: 200, height: 36)
                        .background(.white.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(4, corners: .allCorners)
                }
            }
        } // VStack
        .padding(.bottom, 20)
        .background(Color.backgroundColor)
        .cornerRadius(16, corners: .allCorners)
    }
}

struct TimeOffView_Previews: PreviewProvider {
    static var previews: some View {
        TimeOffView(didSelectdTime: {_ in })
            .previewLayout(.sizeThatFits)
    }
}
