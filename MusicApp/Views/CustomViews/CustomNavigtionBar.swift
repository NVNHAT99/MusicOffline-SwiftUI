//
//  CustomNavigtionBar.swift
//  MusicApp
//
//  Created by Nhat on 5/16/23.
//

import SwiftUI

struct CustomNavigtionBar: View {
    var title: String
    var body: some View {
        VStack {
            ZStack {
                Color.clear
                Text(title)
                    .font(.largeTitle.weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }// VStack
    }
    
}

struct CustomNavigtionBar_Previews: PreviewProvider {
    static var previews: some View {
        CustomNavigtionBar(title: "My Libary")
            .previewLayout(.sizeThatFits)
    }
}
