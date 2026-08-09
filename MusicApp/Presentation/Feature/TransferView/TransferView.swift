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
                .foregroundColor(.primaryText)

                // Tab switcher
                Picker("Method", selection: $selectedTab) {
                    Text("WiFi").tag(TransferTab.wifi)
                    Text("Files App").tag(TransferTab.files)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Scrollable so content is reachable when the mini player /
                // tab bar overlap the bottom — otherwise the lower part of a
                // long section stays hidden and can't be scrolled into view.
                ScrollView(.vertical) {
                    if selectedTab == .wifi {
                        wifiSection
                    } else {
                        filesSection
                    }

                    // Clear the floating mini player (80pt) plus a gap for the
                    // tab bar so the last content isn't hidden behind them.
                    Color.clear
                        .frame(height: DesignToken.Player.miniPlayerHeight + 40)
                }
                .scrollIndicators(.hidden)
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
                    Text(viewModel.state.isServerOn ? "Stop Server" : "Connect Server")
                        .font(AppFont.headline())
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundColor(.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 24)
                        .background(
                            (viewModel.state.isServerOn
                             ? Color.red
                             : Color.accentPrimary).opacity(0.9)
                        )
                        .cornerRadius(12, corners: .allCorners)
                }
                .buttonStyle(.pressScale)
                .padding(.horizontal, 24)

                Spacer().frame(height: 24)

                if viewModel.state.isServerOn {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Open your browser with this URL: ")
                            .font(AppFont.body())

                        HStack(spacing: 8) {
                            Text(viewModel.state.ipAdress ?? "")
                                .foregroundColor(.accentPrimary)
                                .font(AppFont.body())

                            Button {
                                viewModel.send(.copyIPAdress)
                            } label: {
                                Text("Copy URL")
                                    .font(AppFont.caption())
                                    .frame(width: 100)
                                    .padding(6)
                                    .foregroundColor(.primaryText)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(8, corners: .allCorners)
                            }
                            .buttonStyle(.pressScale)
                        }

                        Text("Then upload files from your computer.\nplease don't switch to another app or lock your phone while transfering.")
                            .font(AppFont.callout())
                            .lineLimit(.max)

                        Image("transfer_1")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .cornerRadius(8, corners: .allCorners)
                    }
                    .foregroundColor(.primaryText)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
            .background(Color.white.opacity(0.06))
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
                        .foregroundColor(.accentPrimary)
                    Text("Import from Files App")
                        .font(AppFont.headline())
                        .foregroundColor(.primaryText)
                    Text("Select audio files (.mp3, .flac, .ogg, etc.) directly from your device or iCloud Drive.")
                        .font(AppFont.callout())
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                ImportSongView(viewModel: importViewModel)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color.white.opacity(0.06))
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
