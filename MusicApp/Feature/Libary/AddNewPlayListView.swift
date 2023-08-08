//
//  AddNewPlayListView.swift
//  MusicApp
//
//  Created by Nhat on 6/9/23.
//

import SwiftUI

struct AddNewPlayListView: View {
    // MARK: - PROPERTIES
    @State private var name: String = String.empty
    @State private var heightOfKeyboard: CGFloat = 0.0
    @Environment(\.presentationMode) var presentationMode
    var onCreatePlaylist: ((String) -> Void)?
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.gray.opacity(0.8)
                GeometryReader { proxyVStack in
                    VStack (spacing: 0) {
                        TextField("Enter playlist name", text: $name)
                            .frame(alignment: .center)
                            .padding()
                            .cornerRadius(12)
                            .padding()
                            .shadow(radius: 4)
                            
                        
                        Spacer()
                            .frame(height: 10)
                        Button {
                            if name != String.empty {
                                presentationMode.wrappedValue.dismiss()
                                onCreatePlaylist?(name)
                            }
                        } label: {
                            Text("Create")
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                                .frame(width: 200, height: 40)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white, lineWidth: 2)
                                }
                                
                        }
                        .background(Color.init(hexString: "#24a0ed"))
                        .cornerRadius(24)
                        .shadow(radius: 2)
                        Spacer()
                            .frame(height: 20)
                    }
                    .background(.white)
                    .cornerRadius(12)
                    .shadow(radius: 4)
                    .onTapGesture {}
                    .modifier(CustomModifiers.PushContentKeyboardModifier(heightOfKeyboard: $heightOfKeyboard,
                                                                          offsetYOfView: proxyVStack.frame(in: .global).maxY,
                                                                          isPresented: true))
                }
                .frame(width: proxy.size.width * 0.9, height: 200)
            } // ZSTACK
            .ignoresSafeArea()
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct AddNewPlayListView_Previews: PreviewProvider {
    static var previews: some View {
        AddNewPlayListView()
    }
}
