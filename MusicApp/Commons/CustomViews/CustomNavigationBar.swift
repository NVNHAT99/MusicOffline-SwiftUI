import SwiftUI

// MARK: - Typealias
typealias OnTapAction = () -> Void

// MARK: - NavigationBarButton Struct
struct NavigationBarButton {
    let title: String?
    let icon: String? // SF Symbol name
    let tintColor: Color
    let action: OnTapAction

    init(title: String? = nil,
         icon: String? = nil,
         tintColor: Color = .blue,
         action: @escaping OnTapAction) {
        self.title = title
        self.icon = icon
        self.tintColor = tintColor
        self.action = action
    }
}

// MARK: - NavigationBarType Enum
enum NavigationBarType {
    case large(title: String)
    case backButton(title: String?, tintColor: Color = .blue, action: OnTapAction? = nil)
    case custom(title: String, left: NavigationBarButton?, right: NavigationBarButton?)
}

// MARK: - CustomNavigationBar View
struct CustomNavigationBar: View {
    var type: NavigationBarType

    var body: some View {
        VStack {
            switch type {
            case .large(let title):
                largeTitleView(title)
            case .backButton(let title, let tintColor, let action):
                backButtonView(title: title, tintColor: tintColor, action: action)
            case .custom(let title, let left, let right):
                twoButtonsView(left: left, right: right, title: title)
            }
        }
        .padding(.vertical, 8)
        .background(Color.clear)
    }

    // MARK: - Large Title
    private func largeTitleView(_ title: String) -> some View {
        Text(title)
            .font(.largeTitle.weight(.bold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
    }

    // MARK: - Back Button View
    private func backButtonView(title: String?, tintColor: Color, action: OnTapAction?) -> some View {
        HStack(spacing: 4) {
            Button(action: {
                action?()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(tintColor)

                    if let title = title, !title.isEmpty {
                        Text(title)
                            .foregroundColor(tintColor)
                            .font(.body)
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Two Button View
    private func twoButtonsView(left: NavigationBarButton?,
                                right: NavigationBarButton?,
                                title: String) -> some View {
        ZStack {
            HStack {
                renderButton(left)
                Spacer()
                renderButton(right)
            }
            .padding(.horizontal, 16)

            Text(title)
                .foregroundStyle(.white)
                .lineLimit(1)
                .font(.system(size: 18, weight: .semibold))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Render Single Button
    private func renderButton(_ button: NavigationBarButton?) -> some View {
        Group {
            if let button = button {
                Button(action: button.action) {
                    HStack(spacing: 4) {
                        if let icon = button.icon {
                            Image(systemName: icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        }
                        if let title = button.title {
                            Text(title)
                                .font(.system(size: 18, weight: .semibold))
                        }
                    }
                    .foregroundColor(button.tintColor)
                }
            } else {
                Spacer().frame(width: 44, height: 44)
            }
        }
    }
}

// MARK: - Preview
struct CustomNavigationBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CustomNavigationBar(type: .large(title: "Library"))

            CustomNavigationBar(type: .backButton(title: "Back", tintColor: .blue, action: {
                print("Back tapped")
            }))

            CustomNavigationBar(type: .backButton(title: "Cancel", tintColor: .red))

            CustomNavigationBar(type: .custom(
                title: "Settings",
                left: NavigationBarButton(title: "Cancel", tintColor: .red) {
                    print("Cancel tapped")
                },
                right: NavigationBarButton(icon: "gearshape", tintColor: .blue) {
                    print("Settings tapped")
                }
            ))
            .background(.green)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
