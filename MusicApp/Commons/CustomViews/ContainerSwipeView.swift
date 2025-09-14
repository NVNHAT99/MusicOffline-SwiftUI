//
//  ContainerSwipeView.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 9/2/25.
//

import SwiftUI

struct ContainerSwipeView<Content: View>: View {
    let content: Content
    let onDelete: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isShowingAction = false
    @State private var cellWidth: CGFloat = 0
    @State private var viewHeight: CGFloat = 0.0
    @State private var viewWidth: CGFloat = 0.0
    private let minActionWidth: CGFloat = 80
    
    init(@ViewBuilder content: () -> Content, onDelete: @escaping () -> Void) {
        self.content = content()
        self.onDelete = onDelete
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Dynamic delete background
            Rectangle()
                .fill(Color.red)
            
            HStack {
                Image(systemName: "trash")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .medium))
                    .padding(.trailing, 20)
            }
            .opacity(offset < -minActionWidth ? 1 : 0.7)
            .onTapGesture {
                onDelete()
            }
            
            content
                .frame(maxWidth: .infinity)
                .readSize(onchange: { size in
                    self.viewHeight = size.height
                })
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let translation = value.translation.width
                            if translation < 0 { // swipe left
                                offset = max(translation, -self.viewWidth)
                            } else {
                                // chỉ cho kéo về 0 khi đang mở
                                if isShowingAction {
                                    offset = min(-minActionWidth + translation, 0)
                                } else {
                                    offset = 0
                                }
                            }
                        }
                        .onEnded { value in
                            let translation = value.translation.width
                            
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                if -translation > self.viewWidth * 0.7 {
                                    // full swipe delete
                                    offset = -self.viewWidth
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        onDelete()
                                    }
                                } else if -translation > minActionWidth {
                                    offset = -minActionWidth
                                    isShowingAction = true
                                } else {
                                    offset = 0
                                    isShowingAction = false
                                }
                            }
                        }
                )
                .onAppear {
                    cellWidth = self.viewWidth
                }

        }
        .readSize(onchange: { size in
            self.viewWidth = size.width
        })
        .clipped()
    }
}

// MARK: - Preview
struct ContainerSwipeView_Preview: View {
    @State private var items = ["Item 1", "Item 2", "Item 3", "Item 4"]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        ContainerSwipeView(content: {
                            PlayListItemView(playListName: "thoi duoc roi") {
                                
                            }
                        }, onDelete: {
                            withAnimation {
                                items.removeAll { $0 == item }
                            }
                        })
                        
                    }
                }
            }
            .navigationTitle("Swipe Like List")
        }
    }
}

#Preview {
    ContainerSwipeView_Preview()
}

struct ListSwipePreview: View {
    @State private var items = ["Item 1", "Item 2", "Item 3", "Item 4"]

    var body: some View {
        NavigationView {
            List {
                ForEach(items, id: \.self) { item in
                    HStack {
                        Text(item)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.vertical, 12)
                    .background(.blue)
                    .cornerRadius(8, corners: .allCorners)
                    // SwiftUI built-in swipe action
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            print("Deleted \(item)")
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("List Swipe Preview")
        }
    }
}

#Preview {
    ListSwipePreview()
}
