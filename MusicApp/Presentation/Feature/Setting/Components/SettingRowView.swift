//
//  SettingRowView.swift
//  MusicApp
//

import SwiftUI

struct SettingRowView: View {
    let title: String
    var subtitle: String? = nil
    var showChevron: Bool = true
    var titleColor: Color = .white
    let action: (() -> Void)?

    var body: some View {
        Button(action: { action?() }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(titleColor)
                        .font(.body)
                    if let subtitle {
                        Text(subtitle)
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
                Spacer()
                if showChevron {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .font(.caption)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
