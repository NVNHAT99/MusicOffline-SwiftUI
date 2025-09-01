//
//  AddNewPlayListView.swift
//  MusicApp
//
//  Created by Nhat on 6/9/23.
//

import SwiftUI

struct AddNewPlayListView: View {
    // MARK: - PROPERTIES
    @EnvironmentObject var reloadManager: TabReloadManager
    @StateObject var viewmodel: AddNewPlaylistViewmodel = AddNewPlaylistViewmodel()
    let router: Router<LibaryRouter>
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
            GeometryReader { proxyVStack in
                VStack (spacing: 0) {
                    ZStack(alignment: .leading) {
                        // this view make text field change place holder color
                        // if the new of version of swiftUI have this modifer so you could change
                        if viewmodel.state.playlistName.isEmpty {
                            Text("Enter playlist name here")
                                .foregroundColor(.white.opacity(0.6))
                            .padding(24)
                        }
                        
                        TextField("", text: viewmodel.bindingName())
                            .frame(alignment: .center)
                            .padding(24)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                            .foregroundColor(.white)
                    }

                    
                    Spacer()
                        .frame(height: 10)
                    Button {
                        viewmodel.send(intent: .addNewLibary(onCompleted: {
                            self.reloadManager.resetTab = [.home]
                            self.router.dismiss()
                        }))
                    } label: {
                        Text("Create")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .frame(width: 200, height: 40)
                            .overlay {
                                RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.gray, lineWidth: 2)
                            }
                            
                    }
                    .background(Color.gray)
                    .cornerRadius(24)
                    .shadow(radius: 2)
                    Spacer()
                        .frame(height: 20)
                }
                .background(Color.backgroundColor)
                .cornerRadius(12)
                .shadow(radius: 4)
                .onTapGesture {}
            }
            .frame(height: 200)
            .padding(.horizontal, 24)
            
            if viewmodel.state.isShowToastView {
                VStack {
                    Spacer()
                    ToastView(isShowView: viewmodel.bindingShowToastView, message: viewmodel.state.toastViewMessage, timeShowView: .seconds(2))
                        .frame(height: 60)
                        .padding(.bottom, 16)
                }
            }
        } // ZSTACK
        .ignoresSafeArea()
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            router.dismiss()
        }
    }
}

struct AddNewPlayListView_Previews: PreviewProvider {
    static var previews: some View {
        AddNewPlayListView(viewmodel: AddNewPlaylistViewmodel(),
                           router: .init())
    }
}
