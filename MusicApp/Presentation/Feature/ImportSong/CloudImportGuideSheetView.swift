import SwiftUI

/// Inline guide explaining how to surface third-party cloud providers
/// (Google Drive, Dropbox, OneDrive, etc.) inside the system document picker.
/// iOS hides them by default until the user installs the provider's app and
/// enables it under Files → Browse → Locations.
///
/// Rendered as a permanent header inside ImportSongView (not a one-time sheet)
/// so users can re-read the steps whenever they come back to import.
struct CloudImportGuideContent: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            stepRow(
                number: "1",
                title: "Install the cloud app",
                body: "Install Google Drive, Dropbox, OneDrive, or any cloud app from the App Store.",
                index: 0
            )
            stepRow(
                number: "2",
                title: "Open the Files app",
                body: "Open Apple's Files app, then tap Browse at the bottom.",
                index: 1
            )
            stepRow(
                number: "3",
                title: "Enable the provider",
                body: "Tap the … menu at the top, choose Edit, then toggle on Google Drive (or any provider you want).",
                index: 2
            )
            stepRow(
                number: "4",
                title: "Pick the file here",
                body: "Tap Import from Files below, then switch to your cloud provider from the picker's Browse tab.",
                index: 3
            )

            Divider().padding(.vertical, 2)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle")
                    .foregroundColor(.accentPrimary)
                Text("iOS hides third-party cloud providers until you enable them in Files. We can't auto-enable them.")
                    .font(AppFont.caption())
                    .foregroundColor(.secondaryText)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "icloud.and.arrow.down")
                .font(.system(size: 32))
                .foregroundColor(.accentPrimary)
            VStack(alignment: .leading, spacing: 4) {
                Text("Use Google Drive, Dropbox & more")
                    .font(AppFont.headline())
                    .foregroundColor(.primaryText)
                Text("4 quick steps to add cloud providers to the picker.")
                    .font(AppFont.callout())
                    .foregroundColor(.secondaryText)
            }
        }
    }

    private func stepRow(number: String, title: String, body: String, index: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(AppFont.caption())
                .fontWeight(.bold)
                .foregroundColor(.primaryText)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Color.accentPrimary))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFont.callout())
                    .bold()
                    .foregroundColor(.primaryText)
                Text(body)
                    .font(AppFont.caption())
                    .foregroundColor(.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .entrance(index: index)
    }
}
