//
//  AddNewPlayListView.swift
//  MusicApp
//
//  Created by Nhat on 6/9/23.
//

import SwiftUI

struct AddNewPlayListView: View {
    // MARK: - PROPERTIES
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewmodel: AddNewPlaylistViewmodel
    var onCreatePlaylist: (() -> Void)?
    var onDismiss: () -> Void
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.opacity(0.8)
                GeometryReader { proxyVStack in
                    VStack (spacing: 0) {
                        ZStack(alignment: .leading) {
                            // this view make text field change place holder color
                            // if the new of version of swiftUI have this modifer so you could change
                            if viewmodel.state.name.isEmpty {
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
                            if viewmodel.state.name != String.empty {
                                viewmodel.send(intent: .addNewLibary(onDismiss: {
                                    onCreatePlaylist?()
                                }))
                                
                            }
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
                    .modifier(CustomModifiers.PushContentKeyboardModifier(heightOfKeyboard: viewmodel.bindingHeightOfKeyBoard(),
                                                                          offsetYOfView: proxyVStack.frame(in: .global).maxY,
                                                                          isPresented: true))
                }
                .frame(width: proxy.size.width * 0.9, height: 200)
            } // ZSTACK
            .ignoresSafeArea()
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                onDismiss()
            }
        }
    }
}

struct AddNewPlayListView_Previews: PreviewProvider {
    static var previews: some View {
        AddNewPlayListView(viewmodel: AddNewPlaylistViewmodel(), onDismiss: {})
    }
}
