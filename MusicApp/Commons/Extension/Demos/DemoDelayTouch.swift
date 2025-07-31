import SwiftUI
import UIKit

// MARK: - Refactored SettingsRow
struct SettingsRow: View {
    let item: SettingsItem
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(item.iconColor)
                    .frame(width: 28, height: 28)
                
                Image(systemName: item.icon)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.body)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            switch item.type {
            case .toggle(let binding):
                Toggle("", isOn: binding)
                    .toggleStyle(SettingsToggleStyle())
                    .labelsHidden()
                    
            case .navigation:
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .delaysTouches(
            action: {
                if case .navigation = item.type {
                    action()
                }
            },
            hapticStyle: {
                switch item.type {
                case .navigation: return .light
                case .toggle(_): return nil // Toggle tự xử lý haptic
                }
            }()
        )
    }
}

// MARK: - Supporting Types
struct SettingsItem {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let type: ItemType
    
    enum ItemType {
        case toggle(Binding<Bool>)
        case navigation
    }
}

struct SettingsToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                withAnimation(.easeInOut(duration: 0.2)) {
                    configuration.isOn.toggle()
                }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(configuration.isOn ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 48, height: 28)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                        .shadow(radius: 1)
                        .offset(x: configuration.isOn ? 10 : -10)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - SettingsSection
struct SettingsSection: View {
    let title: String?
    let items: [SettingsItem]
    let onItemTap: (SettingsItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title = title {
                Text(title)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
            }
            
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    SettingsRow(item: item) {
                        onItemTap(item)
                    }
                    
                    if index < items.count - 1 {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - SettingsView
struct SettingsView: View {
    @State private var wifiEnabled = true
    @State private var bluetoothEnabled = true
    @State private var darkModeEnabled = false
    @State private var notificationsEnabled = true
    @State private var airplaneModeEnabled = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 32) {
                    SettingsSection(title: nil, items: [
                        SettingsItem(
                            icon: "airplane",
                            iconColor: .orange,
                            title: "Airplane Mode",
                            subtitle: nil,
                            type: .toggle($airplaneModeEnabled)
                        ),
                        SettingsItem(
                            icon: "wifi",
                            iconColor: .blue,
                            title: "Wi-Fi",
                            subtitle: wifiEnabled ? "MyNetwork" : "Off",
                            type: .toggle($wifiEnabled)
                        ),
                        SettingsItem(
                            icon: "bluetooth",
                            iconColor: .blue,
                            title: "Bluetooth",
                            subtitle: bluetoothEnabled ? "On" : "Off",
                            type: .toggle($bluetoothEnabled)
                        )
                    ]) { item in
                        handleItemTap(item)
                    }
                    
                    SettingsSection(title: nil, items: [
                        SettingsItem(
                            icon: "bell.fill",
                            iconColor: .red,
                            title: "Notifications",
                            subtitle: nil,
                            type: .toggle($notificationsEnabled)
                        ),
                        SettingsItem(
                            icon: "moon.fill",
                            iconColor: .purple,
                            title: "Dark Mode",
                            subtitle: nil,
                            type: .toggle($darkModeEnabled)
                        )
                    ]) { item in
                        handleItemTap(item)
                    }
                    
                    SettingsSection(title: nil, items: [
                        SettingsItem(
                            icon: "gear",
                            iconColor: .gray,
                            title: "General",
                            subtitle: nil,
                            type: .navigation
                        ),
                        SettingsItem(
                            icon: "hand.raised.fill",
                            iconColor: .blue,
                            title: "Privacy & Security",
                            subtitle: nil,
                            type: .navigation
                        ),
                        SettingsItem(
                            icon: "camera.fill",
                            iconColor: .gray,
                            title: "Camera",
                            subtitle: nil,
                            type: .navigation
                        )
                    ]) { item in
                        handleItemTap(item)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func handleItemTap(_ item: SettingsItem) {
        switch item.type {
        case .navigation:
            print("Navigate to \(item.title)")
        case .toggle(_):
            break
        }
    }
}

struct ContentView4_Preview: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
