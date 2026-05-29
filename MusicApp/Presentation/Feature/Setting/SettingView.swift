//
//  SettingTabView.swift
//  MusicApp
//

import SwiftUI

struct SettingView<ViewModel: SettingViewViewModelProtocol>: View {
    @StateObject var viewModel: ViewModel
    @StateObject private var router = Router<AppRoute>()
    @EnvironmentObject private var container: DIContainer

    init(viewModel: ViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            CustomNavigationBar(type: .large(title: "Setting"))
                .frame(height: 70)
                .foregroundColor(.primaryText)
                .padding(.leading, 26)
                .padding(.top, Helper.shared.safeAreaInsets?.top)

            List {
                generalSection()
                aboutSection()
                dangerSection()
            }
            .listStyle(.insetGrouped)
            .foregroundColor(.primaryText)
            .modifier(ListBackgroundModifier())
        }
        .ignoresSafeArea(.all)
        .background(Color.backgroundColor)
        .withRouting(router: self.router)
        .onAppear { router.factory = container }
        // Delete confirmation alert
        .alert("Delete All Songs", isPresented: Binding(
            get: { viewModel.state.isShowDeleteConfirm },
            set: { _ in viewModel.send(intent: .cancelDeleteAllSongs) }
        )) {
            Button("Delete", role: .destructive) { viewModel.send(intent: .confirmDeleteAllSongs) }
            Button("Cancel", role: .cancel) { viewModel.send(intent: .cancelDeleteAllSongs) }
        } message: {
            Text("This will permanently delete all songs from the app. This action cannot be undone.")
        }
        // Share sheet
        .sheet(isPresented: Binding(
            get: { viewModel.state.isShowShareSheet },
            set: { if !$0 { viewModel.send(intent: .cancelShareSheet) } }
        )) {
            ShareSheet(items: [SettingConstants.shareURL])
        }
        .overlay(alignment: .bottom) {
            if viewModel.state.isShowToastView {
                ToastView(isShowView: viewModel.isShowToastView(),
                          message: viewModel.state.messageToastView,
                          timeShowView: .seconds(2))
                    .frame(height: 40)
                    .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func generalSection() -> some View {
        Section(header: Text("General").font(AppFont.caption()).foregroundColor(.mutedText)) {
            SettingRowView(title: "Transfer MP3 Files") {
                NotificationCenter.default.post(name: .switchMainTab, object: MainTab.transfer)
            }
            SettingRowView(title: "Download from URL") {
                router.route(to: .urlDownload)
            }
            SettingRowView(title: "Equalizer") {
                router.route(to: .equalizer)
            }
            SettingRowView(
                title: "Language",
                subtitle: viewModel.state.selectedLanguageDisplay,
                showChevron: false,
                titleColor: .mutedText,
                action: nil
            )
        }
        .listRowBackground(Color.headerBackground)
    }

    @ViewBuilder
    private func aboutSection() -> some View {
        Section(header: Text("About").font(AppFont.caption()).foregroundColor(.mutedText)) {
            SettingRowView(title: "Rate App") {
                viewModel.send(intent: .rateApp)
            }
            SettingRowView(title: "Share App") {
                viewModel.send(intent: .shareApp)
            }
            SettingRowView(title: "Privacy Policy") {
                viewModel.send(intent: .openPrivacy)
            }
            SettingRowView(title: "Terms of Use") {
                viewModel.send(intent: .openTerms)
            }
            SettingRowView(
                title: "Version",
                subtitle: viewModel.state.appVersion,
                showChevron: false,
                action: nil
            )
        }
        .listRowBackground(Color.headerBackground)
    }

    @ViewBuilder
    private func dangerSection() -> some View {
        Section(header: Text("Danger Zone").font(AppFont.caption()).foregroundColor(.red.opacity(0.8))) {
            SettingRowView(title: "Delete All Songs", showChevron: false, titleColor: .red) {
                viewModel.send(intent: .deleteAllSongs)
            }
        }
        .listRowBackground(Color.headerBackground)
    }
}

struct SettingTabView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = SettingViewViewModel()
        return SettingView(viewModel: viewModel)
            .background(Color.backgroundColor)
    }
}
