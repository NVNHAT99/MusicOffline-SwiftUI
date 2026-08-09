//
//  AddNewPlayListView.swift
//  MusicApp
//
//  Created by Nhat on 6/9/23.
//

import SwiftUI

struct AddNewPlayListView<ViewModel: AddNewPlaylistViewModelProtocol>: View {
    // MARK: - PROPERTIES
    @StateObject var viewmodel: ViewModel
    let router: Router<AppRoute>

    init(viewmodel: ViewModel, router: Router<AppRoute>) {
        self._viewmodel = StateObject(wrappedValue: viewmodel)
        self.router = router
    }
    var body: some View {
        ZStack {
            // Dimmed background — works with fullScreenCover
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    router.dismiss()
                }

            VStack(spacing: 0) {
                ZStack(alignment: .leading) {
                    if viewmodel.state.playlistName.isEmpty {
                        Text("Enter playlist name here")
                            .foregroundColor(.mutedText)
                            .padding(24)
                    }
                    TextField("", text: viewmodel.bindingName())
                        .padding(24)
                        .foregroundColor(.primaryText)
                }

                if let nameError = viewmodel.state.nameError {
                    Text(nameError)
                        .foregroundColor(.red)
                        .font(AppFont.caption())
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer().frame(height: 10)

                Button {
                    viewmodel.send(intent: .addNewLibary(onCompleted: {
                        router.dismiss()
                    }))
                } label: {
                    Text("Create")
                        .foregroundColor(.primaryText)
                        .font(AppFont.headline())
                        .frame(width: 200, height: 40)
                        .overlay {
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.accentPrimary, lineWidth: 2)
                        }
                }
                .background(Color.accentPrimary)
                .cornerRadius(24)
                .shadow(radius: 2)
                .buttonStyle(.pressScale)

                Spacer().frame(height: 20)
            }
            .background(Color.backgroundColor)
            .cornerRadius(12)
            .shadow(radius: 4)
            .padding(.horizontal, 24)
            .onTapGesture {} // absorb taps so they don't hit the dimmed BG dismiss

            if viewmodel.state.isShowToastView {
                VStack {
                    Spacer()
                    ToastView(isShowView: viewmodel.bindingShowToastView,
                              message: viewmodel.state.toastViewMessage,
                              timeShowView: .seconds(2))
                        .frame(height: 60)
                        .padding(.bottom, 16)
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct AddNewPlayListView_Previews: PreviewProvider {
    static var previews: some View {
        let container = DIContainer.preview
        AddNewPlayListView(viewmodel: container.makeAddNewPlaylistViewModel(),
                           router: .init())
        .environmentObject(container)
    }
}
