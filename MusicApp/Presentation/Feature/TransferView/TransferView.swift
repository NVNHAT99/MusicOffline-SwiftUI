//
//  TransferView.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 8/1/25.
//

import SwiftUI

struct TransferView<ViewModel: TransferViewModelProtocol>: View {
    @StateObject private var viewModel: ViewModel
    @StateObject private var importViewModel = ImportSongViewModel()
    @EnvironmentObject private var container: DIContainer
    let navigationHandler: Router<AppRoute>
    @State private var showGuide = false
    @State private var selectedTab: TransferTab = .wifi

    enum TransferTab { case wifi, files }

    init(viewModel: ViewModel, navigationHandler: Router<AppRoute>) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.navigationHandler = navigationHandler
    }

    var body: some View {
        ZStack {
            Color.backgroundColor
                .ignoresSafeArea()
            VStack(spacing: 0) {
                CustomNavigationBar(type: .custom(
                    title: "Transfer",
                    left: nil,
                    right: .init(icon: "questionmark.circle", tintColor: .white, action: {
                        showGuide = true
                    })
                ))
                .foregroundStyle(.white)

                // Tab switcher
                Picker("Method", selection: $selectedTab) {
                    Text("WiFi").tag(TransferTab.wifi)
                    Text("Files App").tag(TransferTab.files)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                if selectedTab == .wifi {
                    wifiSection
                } else {
                    filesSection
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)

            if viewModel.state.showLoading {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView()
                    .padding(20)
                    .background(.thinMaterial)
                    .cornerRadius(12)
            }

            if viewModel.state.isShowToastView {
                VStack {
                    Spacer()
                    ToastView(isShowView: viewModel.isShowToastView(),
                              message: viewModel.state.messageToastView,
                              timeShowView: .seconds(2))
                        .frame(height: 40)
                        .padding(.bottom, 16)
                }
            }
        }
        .fullScreenCover(isPresented: $showGuide) {
            TransferGuideView(onDismiss: { showGuide = false })
        }
        .onDisappear {
            // Don't leave the unauthenticated upload server listening on Wi-Fi
            // once the user navigates away from this screen.
            if viewModel.state.isServerOn {
                viewModel.send(.toggleServer)
            }
        }
    }

    // MARK: - WiFi section

    private var wifiSection: some View {
        VStack {
            Spacer().frame(height: 24)
            VStack {
                Button {
                    viewModel.send(.toggleServer)
                } label: {
                    Text(viewModel.state.isServerOn ? "Disconnected Server" : "Connect Server")
                        .frame(width: 160)
                        .padding(16)
                        .foregroundColor(.white)
                        .background(.red.opacity(0.8))
                        .cornerRadius(8, corners: .allCorners)
                }

                Spacer().frame(height: 24)

                if viewModel.state.isServerOn {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Open your browser with this URL: ")

                        HStack(spacing: 8) {
                            Text(viewModel.state.ipAdress ?? "")
                                .foregroundColor(.blue)

                            Button {
                                viewModel.send(.copyIPAdress)
                            } label: {
                                Text("Copy URL")
                                    .frame(width: 100)
                                    .padding(6)
                                    .foregroundColor(.white)
                                    .background(.black.opacity(0.8))
                                    .cornerRadius(8, corners: .allCorners)
                            }
                        }

                        Text("Then upload files from your computer.\nplease don't switch to another app or lock your phone while transfering.")
                            .lineLimit(.max)

                        Image("transfer_1")
                            .resizable()
                            .aspectRatio(1.0, contentMode: .fit)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
            .background(.gray)
            .cornerRadius(10, corners: .allCorners)
            .padding()
        }
    }

    // MARK: - Files App section

    private var filesSection: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 24)
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 44))
                        .foregroundStyle(.cyan)
                    Text("Import from Files App")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("Select audio files (.mp3, .flac, .ogg, etc.) directly from your device or iCloud Drive.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                ImportSongView(viewModel: importViewModel)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(.gray)
            .cornerRadius(10, corners: .allCorners)
            .padding()

            Spacer()
        }
    }
}

#Preview {
    let container = DIContainer.preview
    TransferView(viewModel: container.makeTransferViewModel(), navigationHandler: Router<AppRoute>())
        .environmentObject(container)
        .background(Color.backgroundColor)
}
