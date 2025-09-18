//
//  LoggerExample.swift
//  MusicApp
//
//  Created by Logger on 9/18/25.
//

import Foundation

// MARK: - Example Usage Class
class LoggerExample {

    // // private let logger = // CommonLogger.shared

    // MARK: - Examples of different log levels

    func demonstrateBasicLogging() {
        // Verbose logging - for very detailed debugging
        Logger.verbose("Starting detailed operation")

        // Debug logging - for development debugging
        Logger.debug("User tapped play button")
        Logger.debug("Fetching songs from database")

        // Info logging - general app information
        Logger.info("App launched successfully")
        Logger.info("Playlist loaded with 15 songs")

        // Warning logging - potential issues
        Logger.warning("Low disk space available")
        Logger.warning("Network connection is weak")

        // Error logging - errors and exceptions
        Logger.error("Failed to save playlist")
        Logger.error("Authentication failed")
    }

    // MARK: - Error handling example

    func demonstrateErrorHandling() {
        do {
            try someRiskyOperation()
        } catch {
            // Log the error with full context
            Logger.error(error)
        }
    }

    private func someRiskyOperation() throws {
        // Simulate an error
        throw NSError(domain: "MusicApp", code: 404, userInfo: [NSLocalizedDescriptionKey: "File not found"])
    }

    // MARK: - Performance measurement example

    func demonstratePerformanceMeasurement() {
        let songs = Logger.measureTime(operation: "Fetch Songs") {
            fetchSongsFromDatabase()
        }
        Logger.info("Fetched \(songs.count) songs")
    }

    private func fetchSongsFromDatabase() -> [String] {
        // Simulate database operation
        Thread.sleep(forTimeInterval: 0.5)
        return ["Song 1", "Song 2", "Song 3"]
    }

    // MARK: - App lifecycle events

    func demonstrateAppEventLogging() {
        Logger.logAppEvent("App Did Finish Launching")
        Logger.logAppEvent("App Will Enter Foreground")
        Logger.logAppEvent("App Did Enter Background")
    }

    // MARK: - User action logging

    func demonstrateUserActionLogging() {
        Logger.logUserAction("Tapped Play Button")
        Logger.logUserAction("Created New Playlist")
        Logger.logUserAction("Deleted Song")
        Logger.logUserAction("Shared Playlist")
    }

    // MARK: - Network request logging

    func demonstrateNetworkLogging() {
        Logger.logNetworkRequest("https://api.example.com/songs", method: "GET", statusCode: 200)
        Logger.logNetworkRequest("https://api.example.com/playlists", method: "POST", statusCode: 201)
        Logger.logNetworkRequest("https://api.example.com/auth", method: "GET", statusCode: 401)
    }

    // MARK: - Context logging example

    func demonstrateContextLogging() {
        // These logs will automatically include file, function, and line information
        Logger.debug("Starting data processing")
        processData()
        Logger.info("Data processing completed")
    }

    private func processData() {
        Logger.debug("Processing step 1")
        // ... some processing
        Logger.debug("Processing step 2")
        // ... more processing
    }

    // MARK: - Custom configuration example

    func demonstrateConfiguration() {
        // Configure logging at app startup
        Logger.setup(level: .info, colored: true, timestamp: true, shortenFileNames: true)

        Logger.info("Logger configured for production")
    }
}

// MARK: - Global logging examples

class GlobalLoggerExamples {

    func demonstrateGlobalLogging() {
        // Using global convenience functions
        LogV("Verbose message - only shown in debug mode")
        LogD("Debug message")
        LogI("Info message")
        LogW("Warning message")
        LogE("Error message")

        // Log errors with automatic error handling
        do {
            try someOperation()
        } catch {
            LogE(error)  // Automatically logs error.localizedDescription
        }
    }

    private func someOperation() throws {
        // Simulate operation
    }

    func demonstrateLoggingInMethods() {
        LogD("Starting method execution")

        // Method logic here
        let result = fetchData()

        LogI("Method completed with result: \(result)")
    }

    private func fetchData() -> String {
        LogD("Fetching data from server")
        // Simulate network call
        return "Data received"
    }
}

// MARK: - Real-world usage in ViewModels

class ExampleViewModel {

    // private let logger = // CommonLogger.shared

    func loadData() {
        LogD("ExampleViewModel.loadData() - Starting data loading")

        do {
            let data = try fetchDataFromAPI()
            LogI("Data loaded successfully: \(data.count) items")
        } catch {
            LogE("Failed to load data: \(error)")
            // Show error to user
        }
    }

    func userDidTapPlay() {
        LogI("User tapped play button")

        do {
            try startPlayback()
            LogI("Playback started successfully")
        } catch {
            LogE("Failed to start playback: \(error)")
            // Show error to user
        }
    }

    private func fetchDataFromAPI() throws -> [String] {
        LogD("Fetching data from API...")
        // Simulate API call
        return ["Item 1", "Item 2", "Item 3"]
    }

    private func startPlayback() throws {
        LogD("Starting audio playback...")
        // Simulate playback start
    }
}

// MARK: - Setup Instructions
/*

 HOW TO USE THE LOGGER:

 1. **Basic Logging:**
    // CommonLogger.shared.debug("Debug message")
    // CommonLogger.shared.error("Error message")

 2. **Global Functions (simpler):**
    LogD("Debug message")
    LogE("Error message")

 3. **Error Handling:**
    do {
        try someOperation()
    } catch {
        LogE(error)  // Automatically logs error details
    }

 4. **Performance Measurement:**
    let result = // CommonLogger.shared.measureTime(operation: "Data Fetching") {
        return fetchData()
    }

 5. **App Events:**
    // CommonLogger.shared.logAppEvent("App Did Finish Launching")

 6. **User Actions:**
    // CommonLogger.shared.logUserAction("Tapped Play Button")

 7. **Network Requests:**
    // CommonLogger.shared.logNetworkRequest("https://api.com/api", method: "GET", statusCode: 200)

 8. **Configuration (in AppDelegate or SceneDelegate):**
    LogConfiguration.shared.minimumLevel = .info  // Minimum log level to show
    LogConfiguration.shared.enableColoredOutput = true
    LogConfiguration.shared.includeTimestamp = true

 OUTPUT FORMAT:

 [2025-09-18 20:15:30.123] 🐛 [1] [LibaryViewViewModel] loadData() Line 42 → Starting data loading
 [2025-09-18 20:15:30.456] ℹ️ [2] [LibaryViewViewModel] loadData() Line 48 → Data loaded successfully
 [2025-09-18 20:15:31.789] ❌ [4] [SongRepository] fetchSongs() Line 15 → Error: Failed to connect to database

 LOG LEVELS:
 - .verbose (0) - Very detailed debugging
 - .debug (1) - Development debugging
 - .info (2) - General information
 - .warning (3) - Warning messages
 - .error (4) - Error messages only

 */
