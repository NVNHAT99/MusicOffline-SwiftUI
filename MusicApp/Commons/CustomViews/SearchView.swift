//
//  SearchView.swift
//  EZLearning
//
//  Created by nhatnv12 on 10/11/24.
//

import SwiftUI

struct SearchBoxView: View {
    @Binding var text: String
    let placeholder: String
    var iconName: String = "magnifyingglass"

    var backgroundColor: Color = Color.white.opacity(0.08)
    var textColor: Color = .primaryText
    var iconColor: Color = .mutedText
    var height: CGFloat = 40
    var cornerRadius: CGFloat = 10
    var padding: CGFloat = 8
    var showClearButton: Bool = true
    var maxHeight: CGFloat = 60
    var maxPadding: CGFloat = 20

    var body: some View {
        let clampedHeight = min(height, maxHeight)
        let clampedPadding = min(padding, maxPadding)

        HStack(spacing: 8) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .accessibilityLabel(Text("Search"))

            TextField(placeholder, text: $text)
                .foregroundColor(textColor)
                .font(AppFont.body())
                .autocorrectionDisabled()
                .accessibilityLabel(Text(placeholder))

            if showClearButton && !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(iconColor)
                }
                .buttonStyle(.pressScale)
            }
        }
        .padding(.horizontal, clampedPadding)
        .frame(height: clampedHeight)
        .background(backgroundColor)
        .cornerRadius(cornerRadius)
    }
}

// MARK: - Preview
struct SearchBoxView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SearchBoxView(
                text: .constant(""),
                placeholder: "Search..."
            )
            .padding(.horizontal)

            SearchBoxView(
                text: .constant("Hello"),
                placeholder: "Search...",
                height: 44
            )
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color.backgroundColor)
        .previewLayout(.sizeThatFits)
    }
}
