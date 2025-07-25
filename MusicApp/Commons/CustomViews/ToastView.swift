//
//  ToastView.swift
//  MusicApp
//
//  Created by Nhat on 10/1/23.
//

import SwiftUI

struct ToastView: View {
    @Binding var isShowView: Bool
    let message: String
    let timeShowView: DispatchTimeInterval
    var body: some View {
        ZStack {
            Color.gray.opacity(0.6)
            
            VStack {
                Text(message)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .lineLimit(2)
            }
        }
        .cornerRadius(10)
        .transition(.opacity)
        .frame(width: (Helper.shared.keyWindown?.bounds.width ?? 40) - 100)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + timeShowView) {
                isShowView = false
            }
        }
    }
}

struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        ToastView(isShowView: .constant(true), message: "nothing in here",  timeShowView: .seconds(2))
    }
}
