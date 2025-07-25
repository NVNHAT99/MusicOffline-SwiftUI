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
    
    var backgroundColor: Color = Color(.systemGray6)
    var textColor: Color = .primary
    var iconColor: Color = .gray
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
                .autocorrectionDisabled()
                .accessibilityLabel(Text(placeholder))

            if showClearButton && !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(iconColor)
                }
                .buttonStyle(.plain)
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
            // Default style
            SearchBoxView(
                text: .constant(""),
                placeholder: "Search..."
            )
            .padding(.horizontal)
            
            // Custom style
            SearchBoxView(
                text: .constant(""),
                placeholder: "Custom search...",
                backgroundColor: .blue.opacity(0.1),
                textColor: .blue,
                iconColor: .blue,
                height: 100,
                cornerRadius: 20,
                padding: 12
            )
            .padding(.horizontal)
        }
        .previewLayout(.sizeThatFits)
    }
}
