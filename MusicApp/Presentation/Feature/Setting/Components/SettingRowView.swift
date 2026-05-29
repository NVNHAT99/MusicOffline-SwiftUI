//
//  SettingRowView.swift
//  MusicApp
//

import SwiftUI

struct SettingRowView: View {
    let title: String
    var subtitle: String? = nil
    var showChevron: Bool = true
    var titleColor: Color = .primaryText
    let action: (() -> Void)?

    var body: some View {
        Button(action: { action?() }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(titleColor)
                        .font(AppFont.body())
                    if let subtitle {
                        Text(subtitle)
                            .foregroundColor(.mutedText)
                            .font(AppFont.caption())
                    }
                }
                Spacer()
                if showChevron {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.mutedText)
                        .font(AppFont.caption())
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.pressScale)
    }
}
