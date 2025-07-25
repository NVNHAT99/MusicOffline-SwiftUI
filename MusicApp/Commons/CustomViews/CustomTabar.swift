//
//  CustomTabar.swift
//  MusicApp
//
//  Created by Nhat on 5/11/23.
//

import SwiftUI

struct TabItem: Identifiable {
    let id = UUID()
    let image: String
    let title: String
}

struct CustomTabar: View {
    @Binding var tabSelection: Tab
    var items: [TabItem]
    var body: some View {
        HStack {
            Spacer()
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                Button {
                    switch index {
                    case 0:
                        tabSelection = .home
                    case 1:
                        tabSelection = .libary
                    case 2:
                        tabSelection = .setting
                    default:
                        tabSelection = .home
                    }
                } label: {
                    VStack (spacing: 8){
                        Image(systemName: item.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundColor(index + 1 == tabSelection.rawValue ? .white : .gray)
                        Text(item.title)
                            .font(.system(size: 14))
                    }
                }
                Spacer()
            }
        }
        .padding(.top, 20)
    }
}

struct CustomTabar_Previews: PreviewProvider {
    static let items = [TabItem(image: "house", title: "Home"),
                 TabItem(image: "house", title: "Libary")]
    static var previews: some View {
        CustomTabar(tabSelection: .constant(.libary), items: items)
            .previewLayout(.sizeThatFits)
    }
}
