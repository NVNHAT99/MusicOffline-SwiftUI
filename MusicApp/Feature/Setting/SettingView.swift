//
//  SettingTabView.swift
//  MusicApp
//
//  Created by Nhat on 5/18/23.
//

import SwiftUI

struct SettingView: View {
    // MARK: - properties
    @State private var isOnTimer: Bool = false
    // MARK: - display file name as song title
    @State private var isOnDisPlayFileName: Bool = false
    @State private var isOnAllowDupicate: Bool = false
    init() {
        let appearance = UITableView.appearance()
        appearance.backgroundColor = UIColor(cgColor: Color.backgroundColor.cgColor ?? UIColor.gray.cgColor)
    }
    let webServerWrapper = WebServerWrapper()
    var body: some View {
        ZStack(alignment: .top) {
            Color.backgroundColor
            List {
                Section {
                    Text("Import from drive")
                        .onTapGesture {
                            webServerWrapper.start()
                        }
                    NavigationLink {
                        
                    } label: {
                        Text("Remove Ads. buy now")
                    }
                    
                }
                .listRowBackground(Color.headerBackground)
                
                Section {
                    
                    Toggle("Turn on timer to stop playing\nmusic", isOn: $isOnTimer)
                    Toggle("Display file names as song titles", isOn: $isOnDisPlayFileName)
                    Toggle("Allow upload dupicate files", isOn: $isOnAllowDupicate)
                    
                }
                .listRowBackground(Color.headerBackground)
                
                Section {
                    Text("Delete all songs")
                }
                .listRowBackground(Color.headerBackground)
            }
            .padding(.top, (Helper.shared.safeAreaInsets?.top ?? 0) + 70)
            .listStyle(.insetGrouped)
            .foregroundColor(.white)
            
            
            
            
            CustomNavigtionBar(title: "Setting")
                .frame(height: 70)
                .foregroundColor(.white)
                .padding(.top, Helper.shared.safeAreaInsets?.top)
                .padding(.leading, 26)
        }
        .ignoresSafeArea(.all)
        
    }
}

struct SettingTabView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}