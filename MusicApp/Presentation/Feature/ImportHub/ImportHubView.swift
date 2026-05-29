import SwiftUI

/// One screen that lists every way the user can get music into the app.
/// 3 active routes (Files / URL / Web Transfer) + 2 info-only entries
/// (AirDrop, iTunes Sharing) so the user knows those work too.
struct ImportHubView: View {

    @EnvironmentObject var router: Router<AppRoute>
    @Environment(\.dismiss) private var dismiss

    @State private var infoAlert: InfoAlert? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundColor.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Choose how to add music")
                            .font(AppFont.headline())
                            .foregroundColor(.primaryText)
                        rows
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Add Music")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.primaryText)
                }
            }
            .alert(item: $infoAlert) { info in
                Alert(title: Text(info.title), message: Text(info.message), dismissButton: .default(Text("OK")))
            }
        }
    }

    private var rows: some View {
        VStack(spacing: 10) {
            row(icon: "folder.badge.plus", tint: Color.accentPrimary,
                title: "Pick from Files",
                subtitle: "Browse iCloud Drive, Google Drive, Dropbox, local — anywhere Files supports.",
                index: 0) {
                NotificationCenter.default.post(name: .openImportFromFiles, object: nil)
                dismiss()
            }
            row(icon: "link.circle.fill", tint: Color.accentPrimary,
                title: "Download from URL",
                subtitle: "Paste an HTTPS link to an MP3/M4A/WAV. Up to 200 MB.",
                index: 1) {
                router.route(to: .urlDownload)
            }
            row(icon: "wifi.circle.fill", tint: Color.accentPrimary,
                title: "Web Transfer (WiFi)",
                subtitle: "Upload from a browser on the same network — no cable.",
                index: 2) {
                NotificationCenter.default.post(name: .switchMainTab, object: MainTab.transfer)
                dismiss()
            }
            row(icon: "airplayaudio", tint: Color.mutedText,
                title: "AirDrop & Share Sheet",
                subtitle: "Just AirDrop or share an audio file to this app — works automatically.",
                index: 3) {
                infoAlert = InfoAlert(
                    title: "AirDrop & Share",
                    message: "On another device, select an audio file → Share → AirDrop (or another app's Share Sheet) and pick MusicApp. The file imports automatically."
                )
            }
            row(icon: "desktopcomputer", tint: Color.mutedText,
                title: "iTunes / Finder File Sharing",
                subtitle: "Drag files into MusicApp from Finder on macOS.",
                index: 4) {
                infoAlert = InfoAlert(
                    title: "Finder File Sharing",
                    message: "Connect your device → open Finder → select your device → Files tab → drag MP3s into MusicApp. They appear in your library on next launch."
                )
            }
        }
    }

    private func row(icon: String, tint: Color, title: String, subtitle: String, index: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(tint)
                    .frame(width: 38)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppFont.callout())
                        .foregroundColor(.primaryText)
                    Text(subtitle)
                        .font(AppFont.caption())
                        .foregroundColor(.mutedText)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.mutedText)
                    .font(.system(size: 12))
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
        }
        .buttonStyle(.pressScale)
        .entrance(index: index)
    }
}

private struct InfoAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

extension Notification.Name {
    /// Posted from Import Hub when user picks "Pick from Files" — Settings or Library
    /// listens and presents the existing ImportSong screen.
    static let openImportFromFiles = Notification.Name("openImportFromFiles")
}
