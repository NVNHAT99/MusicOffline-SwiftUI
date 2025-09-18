# Common Logger System

A comprehensive logging system for iOS apps with detailed file, function, and line number tracking.

## Features

- 🎯 **Detailed Context**: Automatically captures file name, function name, and line number
- 🎨 **Colored Output**: Color-coded log levels for better readability
- 📊 **Multiple Log Levels**: Verbose, Debug, Info, Warning, Error
- ⚡ **Performance Measurement**: Built-in timing utility
- 🔄 **Global Functions**: Easy-to-use global logging functions
- 📱 **iOS Integration**: Native iOS logging with OSLog
- ⚙️ **Configurable**: Runtime configuration options
- 🔍 **Error Handling**: Automatic error logging with context

## Quick Start

### Basic Usage

```swift
import Foundation

// Use global functions (recommended)
LogD("Debug message")        // Debug level
LogI("Info message")         // Info level
LogW("Warning message")      // Warning level
LogE("Error message")        // Error level

// Log errors automatically
do {
    try someRiskyOperation()
} catch {
    LogE(error)  // Automatically logs error details
}
```

### Class-based Usage

```swift
class MyViewModel {
    private let logger = CommonLogger.shared

    func loadData() {
        Logger.debug("Starting data loading")

        do {
            let data = try fetchData()
            Logger.info("Data loaded successfully: \(data.count) items")
        } catch {
            Logger.error("Failed to load data: \(error)")
        }
    }
}
```

## Log Levels

| Level | Value | Emoji | Color | Description |
|-------|-------|-------|-------|-------------|
| `.verbose` | 0 | 🔍 | White | Very detailed debugging |
| `.debug` | 1 | 🐛 | Cyan | Development debugging |
| `.info` | 2 | ℹ️ | Green | General information |
| `.warning` | 3 | ⚠️ | Yellow | Warning messages |
| `.error` | 4 | ❌ | Red | Error messages |

## Output Format

```
[2025-09-18 20:15:30.123] 🐛 [1] [LibaryViewViewModel] loadData() Line 42 → Starting data loading
[2025-09-18 20:15:30.456] ℹ️ [2] [LibaryViewViewModel] loadData() Line 48 → Data loaded successfully
[2025-09-18 20:15:31.789] ❌ [4] [SongRepository] fetchSongs() Line 15 → Error: Failed to connect to database
```

## Configuration

Configure logging at app startup (AppDelegate/SceneDelegate):

```swift
// Configure logging at app startup
Logger.setup(level: .debug, colored: true, timestamp: true, shortenFileNames: true)
```

## Advanced Features

### Performance Measurement

```swift
// Measure execution time automatically
let result = CommonLogger.shared.measureTime(operation: "Data Fetching") {
    return fetchDataFromAPI()
}

// Output: "Data Fetching took 234.567ms"
```

### App Event Logging

```swift
CommonLogger.shared.logAppEvent("App Did Finish Launching")
CommonLogger.shared.logAppEvent("App Will Enter Foreground")
CommonLogger.shared.logAppEvent("App Did Enter Background")
```

### User Action Logging

```swift
CommonLogger.shared.logUserAction("Tapped Play Button")
CommonLogger.shared.logUserAction("Created New Playlist")
CommonLogger.shared.logUserAction("Deleted Song")
```

### Network Request Logging

```swift
CommonLogger.shared.logNetworkRequest(
    "https://api.example.com/songs",
    method: "GET",
    statusCode: 200
)
```

## Best Practices

### 1. Use Appropriate Log Levels

```swift
// ✅ Good: Use appropriate levels
LogD("Starting API call to \(endpoint)")      // Debug only
LogI("User logged in successfully")          // General info
LogW("Low disk space: \(availableSpace)GB") // Warning
LogE("Authentication failed: \(error)")      // Errors

// ❌ Avoid: Using error level for debug info
LogE("User tapped button") // Should be LogD or LogI
```

### 2. Include Context in Messages

```swift
// ✅ Good: Include relevant context
LogE("Failed to save playlist '\(playlist.name)': \(error)")

// ❌ Avoid: Generic messages
LogE("Save failed")
```

### 3. Use @autoclosure for Performance

```swift
// ✅ Good: Uses @autoclosure - message only evaluated if needed
LogD("Complex object: \(complexObject.description)")

// ❌ Avoid: String interpolation happens even if log level filters it out
Logger.debug("Complex object: \(complexObject.description)")
```

### 4. Error Handling Patterns

```swift
// ✅ Good: Comprehensive error logging
func fetchData() async throws -> [Data] {
    do {
        let result = try await apiService.fetch()
        LogI("Fetched \(result.count) items")
        return result
    } catch let error as APIError {
        LogE("API Error: \(error.localizedDescription)")
        throw error
    } catch {
        LogE("Unexpected error: \(error)")
        throw AppError.unknown
    }
}

// ❌ Avoid: Silent failures
func fetchData() async throws -> [Data] {
    try? await apiService.fetch() // No logging
}
```

## File Structure

```
Commons/Logger/
├── CommonLogger.swift          # Main logger implementation
├── LoggerExample.swift        # Usage examples and patterns
└── README.md                  # This documentation
```

## Integration Steps

1. **Add Files**: Copy `CommonLogger.swift` to your project
2. **Configure**: Set up logging configuration in AppDelegate
3. **Import**: No import needed (uses Foundation)
4. **Use**: Start logging with `LogD()`, `LogI()`, etc.

## Debugging Tips

### Filter Logs in Xcode Console

```
// Show only errors
category:MusicApp log: error

// Show specific file logs
category:MusicApp filename:LibaryViewViewModel

// Show debug messages
category:MusicApp log: debug
```

### Production Logging

```swift
// In release builds, reduce log level
#if DEBUG
Logger.setup(level: = .debug
#else
Logger.setup(level: = .warning
#endif
```

### Performance Considerations

```swift
// Expensive operations - use conditional logging
if Logger.debug.isEnabled {
    let debugInfo = generateExpensiveDebugReport()
    Logger.debug(debugInfo)
}

// Or use @autoclosure (recommended)
Logger.debug(generateExpensiveDebugReport())
```

## Troubleshooting

### No Output in Console

1. Check logging configuration: `Logger.setup(level:colored:timestamp:shortenFileNames:)`
2. Ensure you're using the correct log level
3. Check if logs are filtered by minimum level

### Color Codes Not Working

Colors only work in terminal/Xcode console, not in device logs.

### Performance Issues

- Use appropriate log levels
- Avoid expensive string operations in debug logs
- Consider @autoclosure for expensive message generation

## Migration from NSLog/print()

### Before:
```swift
print("Loading data: \(data)")
NSLog(@"Error: %@", error.localizedDescription)
```

### After:
```swift
LogD("Loading data: \(data)")
LogE("Error: \(error.localizedDescription)")
```

## Contributing

When adding logging to new features:

1. Use appropriate log levels
2. Include context in messages
3. Follow established patterns
4. Test with different log level configurations

## License

This logger system is part of the MusicApp project.
