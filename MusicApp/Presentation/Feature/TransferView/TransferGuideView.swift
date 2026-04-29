//
//  TransferGuideView.swift
//  MusicApp
//

import SwiftUI

struct TransferGuideView: View {
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.backgroundColor.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("How to Transfer")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        guideStep(
                            number: "1",
                            title: "Connect to same Wi-Fi",
                            description: "Make sure your phone and computer are on the same Wi-Fi network."
                        )

                        guideStep(
                            number: "2",
                            title: "Start the server",
                            description: "Tap \"Connect Server\" to start the local transfer server."
                        )

                        guideImage("tap_connect")

                        guideStep(
                            number: "3",
                            title: "Open URL on computer",
                            description: "Copy the URL shown and open it in your browser on your computer."
                        )

                        guideImage("open_url_browser")

                        guideStep(
                            number: "4",
                            title: "Upload files",
                            description: "Select MP3, M4A, WAV, FLAC or AAC files and upload them. Keep the app open during transfer."
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
    }

    @ViewBuilder
    private func guideImage(_ name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .cornerRadius(12)
    }

    @ViewBuilder
    private func guideStep(number: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 32, height: 32)
                Text(number)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
