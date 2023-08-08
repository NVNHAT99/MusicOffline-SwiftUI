//
//  AddNewSongs.swift
//  MusicApp
//
//  Created by Nhat on 8/5/23.
//

import SwiftUI

struct AddNewSongs: View {
    var body: some View {
        VStack {
            CustomNavigationBar(type: .twoButtons(leftAction: nil,
                                                  leftTitle: "nothing",
                                                  leftIcon: String.empty,
                                                  rightAction: nil,
                                                  rightTitle: "Cancel",
                                                  rightIcon: String.empty,
                                                  title: "Selection Songs"))
            .frame(height: 100)
            .background(.gray)
        }
    }
}

struct AddNewSongs_Previews: PreviewProvider {
    static var previews: some View {
        AddNewSongs()
    }
}
