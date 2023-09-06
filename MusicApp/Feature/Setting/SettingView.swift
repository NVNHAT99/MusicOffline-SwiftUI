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
    var body: some View {
        VStack {
            CustomNavigationBar(type: .larger("Setting"))
                .frame(height: 70)
                .foregroundColor(.white)
                .padding(.leading, 26)
                .background(Color.backgroundColor)
                .padding(.top, Helper.shared.safeAreaInsets?.top)
            
            List {
                Section {
                    Text("Import from drive")
                        .onTapGesture {
                            WebServerWrapper.shared.startWebUploader()
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
            .listStyle(.insetGrouped)
            .foregroundColor(.white)
            .navigationBarHidden(true)
            .modifier(ListBackgroundModifier())
        }
        .ignoresSafeArea(.all)
        .background(Color.backgroundColor)
    }
}

struct SettingTabView_Previews: PreviewProvider {
    static var previews: some View {
        SettingView()
    }
}
