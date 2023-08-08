//
//  PlaylistDetail.swift
//  MusicApp
//
//  Created by Nhat on 7/13/23.
//

import SwiftUI

struct PlaylistDetail: View {
    // MARK: - PROPERTIES
    let tempData: [Int] = [1, 2, 3, 4, 5, 6]
    @Environment(\.presentationMode) private var presentationMode
    var body: some View {
        VStack(alignment: .leading) {
            CustomNavigationBar(type: .twoButtons(leftAction: { presentationMode.wrappedValue.dismiss() },
                                                  leftTitle: "Back",
                                                  leftIcon: "chevron.left",
                                                  rightAction: {
                let documentFileManager = DocumentFileManager()
                let musicFiles = documentFileManager.loadMP3File()
                for file in musicFiles {
                    print(file.fileName)
                }
            },
                                                  rightTitle: "Add new",
                                                  rightIcon: String.empty,
                                                  title: "nothing"))
                .frame(height: 50)
                .background(Color.backgroundColor)
            List {
                ForEach(tempData, id: \.self) { _ in
                    SongItemView(data: SongItemData(name: "see you again", image: "", time: "", albumName: "nothing"))
                }
            }
        }
        .navigationBarHidden(true)
        .background(Color.backgroundColor)
    }
}

struct LibaryDetail_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistDetail()
    }
}


extension VerticalAlignment {
    private enum TopAlignmentGuide: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            return context[VerticalAlignment.top]
        }
    }
    static let topAlignmentGuide = VerticalAlignment(TopAlignmentGuide.self)
}
