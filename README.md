# 🎵 MusicOffline-SwiftUI

A modern, feature-rich offline music player built with SwiftUI that allows users to store, manage, and play their music collection locally on iOS devices.

## ✨ Features

### 🎧 Core Music Player
- **Full Playback Controls**: Play, pause, next, previous, seek
- **Advanced Controls**: Shuffle, repeat modes (none, one, all)
- **Background Playback**: Continues playing when app is in background
- **Bluetooth Support**: Works with Bluetooth audio devices
- **Sleep Timer**: Schedule automatic playback stop

### 📁 Library Management
- **Music Library**: Browse and organize your music collection
- **Smart Search**: Find songs, artists, and albums quickly
- **Metadata Display**: View detailed song information
- **Album Artwork**: Automatic cover art extraction and display

### 📝 Playlist System
- **Create Playlists**: Build custom playlists from your music library
- **Edit & Organize**: Add/remove songs, reorder tracks
- **Recent Playlists**: Quick access to recently created playlists

### 🌐 Web File Transfer
- **WiFi Upload**: Transfer music files via web browser
- **No Computer Needed**: Upload directly to your device
- **Real-time Progress**: Monitor upload status and file operations
- **Multi-format Support**: Supports common audio formats

### 🎨 Modern UI/UX
- **Clean SwiftUI Interface**: Modern, intuitive design
- **Tab Navigation**: Easy access to all features
- **Now Playing Screen**: Beautiful player interface with animations
- **Dark Mode Support**: Automatic theme switching
- **Smooth Animations**: Polished transitions and interactions

## 🏗️ Architecture

This app follows **Clean Architecture + MVVM** patterns with modern SwiftUI practices:

```
MusicApp/
├── Core/                    # Core services and dependency injection
├── Data/                    # Data layer (repositories, CoreData)
├── Domain/                  # Business logic (entities, use cases)
├── Presentation/            # UI layer (views, viewmodels, states)
├── Commons/                 # Shared utilities, extensions, routing
└── Assets.xcassets/          # App resources
```

### Key Architectural Patterns

- **MVVM + State Pattern**: Each feature has State, Intent, and ViewModel
- **Unidirectional Data Flow**: State → Intent → ViewModel → State
- **Dependency Injection**: Centralized through `AppDependencies`
- **Clean Architecture**: Clear separation of concerns across layers
- **Protocol-Oriented**: Extensive use of protocols for testability

### Data Management

- **CoreData**: Local database for songs and playlists
- **Repository Pattern**: Clean data access layer
- **Use Cases**: Business logic encapsulation
- **Entity Mapping**: Between CoreData and domain models

## 📋 Requirements

- **iOS 15.0+**
- **Xcode 13.0+**
- **Swift 5.5+**

## 🚀 Installation

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/MusicOffline-SwiftUI.git
cd MusicOffline-SwiftUI
```

### 2. Install Dependencies
This project uses CocoaPods for dependency management:

```bash
# Install CocoaPods if you haven't already
gem install cocoapods

# Install dependencies
pod install
```

### 3. Open the Project
```bash
# Open the workspace (not the project file)
open MusicApp.xcworkspace
```

### 4. Build and Run
- Select your target device or simulator
- Press `Cmd + R` to build and run

## 📦 Dependencies

### CocoaPods
- **GCDWebServer/WebUploader** (~> 3.0): Web server for file uploads

### Native iOS Frameworks
- **SwiftUI**: Modern UI framework
- **CoreData**: Data persistence
- **AVFoundation**: Audio playback
- **Combine**: Reactive programming
- **Foundation**: Core utilities

## 🔧 Configuration

### App Capabilities
Ensure the following capabilities are enabled in your Xcode project:

- **Background Modes**:
  - Audio
  - Background processing
- **Bluetooth**: For audio device connectivity
- **File Sharing**: For iTunes file sharing

### Key Settings
- **Deployment Target**: iOS 15.0+
- **Dynamic Frameworks**: Enabled (`use_frameworks!`)

## 📱 Usage Guide

### Adding Music to Your Library

1. **Via Web Upload**:
   - Open Settings → Web Transfer
   - Start the web server
   - Connect to the displayed IP address from your computer
   - Upload music files through the web interface

2. **Via File Sharing**:
   - Connect your device to iTunes/Finder
   - Use File Sharing to add music files

### Creating Playlists

1. Go to Library tab
2. Tap "Create New Playlist"
3. Add songs from your library
4. Organize and save your playlist

### Using the Music Player

1. Select any song from your library or playlist
2. Use the now playing screen for full controls
3. Access mini player from bottom tab bar
4. Control playback from lock screen or control center

## 🛠️ Development

### Project Structure

#### Core Components
- `PlayerManager`: Audio playback engine
- `WebServerGCDService`: Web file transfer server
- `CoreDataManager`: Database operations
- `ImageCacheManager`: Efficient image loading
- `AppDependencies`: Dependency injection container

#### Architecture Layers
- **Domain**: Business entities (Song, Playlist, Album)
- **Data**: Repositories, CoreData models, mappers
- **Presentation**: SwiftUI views, ViewModels, State/Intent patterns
- **Common**: Utilities, extensions, routing system

### Key Design Patterns

#### MVVM-Store Pattern
Each feature follows this structure:
```swift
// State - Represents UI state
struct HomeViewState {
    var songs: [Song] = []
    var playlists: [Playlist] = []
    var isLoading: Bool = false
}

// Intent - Handles user actions
enum HomeIntent {
    case onLoad
    case refreshData
    case selectSong(Song)
}

// ViewModel - Business logic
class HomeViewModel: ObservableObject {
    @Published var state = HomeViewState()

    func send(_ intent: HomeIntent) {
        // Handle intent and update state
    }
}
```

#### Repository Pattern
```swift
protocol SongRepositoryProtocol {
    func fetchSongs() async throws -> [Song]
    func addSong(_ song: Song) async throws
    func deleteSong(_ song: Song) async throws
}
```

### Adding New Features

1. **Create Domain Layer**: Add entities and use cases
2. **Implement Data Layer**: Add repositories and CoreData models
3. **Build Presentation Layer**: Create views and ViewModels
4. **Update Dependencies**: Add to `AppDependencies`
5. **Register Routes**: Add navigation paths if needed

## 🧪 Testing

The project is structured to support comprehensive testing:

- **Unit Tests**: Test business logic, use cases, repositories
- **UI Tests**: Test user interactions and flows
- **Integration Tests**: Test data layer and service integration

### Running Tests
```bash
# Run unit tests
xcodebuild test -scheme MusicApp -destination 'platform=iOS Simulator,name=iPhone 14'

# Run all tests
xcodebuild test -scheme MusicApp
```

## 🐛 Troubleshooting

### Common Issues

1. **Web Server Not Accessible**:
   - Ensure device and computer are on the same WiFi network
   - Check firewall settings
   - Verify the IP address is correct

2. **Music Not Playing**:
   - Check file format compatibility
   - Ensure audio permissions are granted
   - Verify background audio capability is enabled

3. **Build Errors**:
   - Run `pod install` to update dependencies
   - Clean build folder (`Cmd + Shift + K`)
   - Check Xcode and iOS version compatibility

### Debug Features

- **Comprehensive Logging**: Built-in logging system for debugging
- **State Inspection**: ViewModels expose state for debugging
- **Network Monitoring**: Web server operation logging

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 Support

For support, feature requests, or bug reports:

- Create an issue on GitHub
- Check existing issues for solutions
- Review the code comments for implementation details

## 🙏 Acknowledgments

- **GCDWebServer**: For the web server functionality
- **SwiftUI Community**: For inspiration and best practices
- **Apple Documentation**: For framework guidance

---

**Built with ❤️ using SwiftUI and modern iOS development practices**