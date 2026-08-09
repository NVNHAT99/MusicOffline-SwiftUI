//
//  CommonLogger.swift
//  MusicApp
//
//  Created by Logger on 9/18/25.
//

import Foundation
import os

// MARK: - Log Level
enum LogLevel: Int, CaseIterable {
    case verbose = 0
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4

    var osLogType: OSLogType {
        switch self {
        case .verbose, .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }

    var emoji: String {
        switch self {
        case .verbose: return "🔍"
        case .debug: return "🐛"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }

    var colorCode: String {
        switch self {
        case .verbose: return "\u{001B}[37m" // White
        case .debug: return "\u{001B}[36m"   // Cyan
        case .info: return "\u{001B}[32m"    // Green
        case .warning: return "\u{001B}[33m" // Yellow
        case .error: return "\u{001B}[31m"   // Red
        }
    }
}

// MARK: - Simple Logger
struct Logger {

    // MARK: - Configuration
    #if DEBUG
    private static let defaultLevel: LogLevel = .debug
    #else
    private static let defaultLevel: LogLevel = .warning
    #endif

    private static var minimumLevel: LogLevel = defaultLevel
    private static var enableColoredOutput: Bool = true
    private static var includeTimestamp: Bool = true
    private static var fileNameShortening: Bool = true

    // MARK: - Configuration Methods
    static func setup(level: LogLevel = defaultLevel,
                      colored: Bool = true,
                      timestamp: Bool = true,
                      shortenFileNames: Bool = true) {
        // In release builds never log below .warning, regardless of the
        // requested level — this keeps file paths / server URL / IP out of
        // the device console.
        minimumLevel = level.rawValue >= defaultLevel.rawValue ? level : defaultLevel
        enableColoredOutput = colored
        includeTimestamp = timestamp
        fileNameShortening = shortenFileNames
    }

    // MARK: - Basic Logging
    static func verbose(_ message: @autoclosure () -> Any,
                       _ file: String = #file,
                       _ function: String = #function,
                       _ line: Int = #line,
                       _ column: Int = #column) {
        log(.verbose, message(), file: file, function: function, line: line, column: column)
    }

    static func debug(_ message: @autoclosure () -> Any,
                      _ file: String = #file,
                      _ function: String = #function,
                      _ line: Int = #line,
                      _ column: Int = #column) {
        log(.debug, message(), file: file, function: function, line: line, column: column)
    }

    static func info(_ message: @autoclosure () -> Any,
                     _ file: String = #file,
                     _ function: String = #function,
                     _ line: Int = #line,
                     _ column: Int = #column) {
        log(.info, message(), file: file, function: function, line: line, column: column)
    }

    static func warning(_ message: @autoclosure () -> Any,
                       _ file: String = #file,
                       _ function: String = #function,
                       _ line: Int = #line,
                       _ column: Int = #column) {
        log(.warning, message(), file: file, function: function, line: line, column: column)
    }

    static func error(_ message: @autoclosure () -> Any,
                      _ file: String = #file,
                      _ function: String = #function,
                      _ line: Int = #line,
                      _ column: Int = #column) {
        log(.error, message(), file: file, function: function, line: line, column: column)
    }

    static func error(_ error: Error,
                      _ file: String = #file,
                      _ function: String = #function,
                      _ line: Int = #line,
                      _ column: Int = #column) {
        let errorMessage = "Error: \(error.localizedDescription)"
        log(.error, errorMessage, file: file, function: function, line: line, column: column)
    }

    // MARK: - Special Logging
    static func measureTime<T>(operation: String,
                              _ file: String = #file,
                              _ function: String = #function,
                              _ line: Int = #line,
                              _ column: Int = #column,
                              _ block: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            debug("\(operation) took \(String(format: "%.3f", timeElapsed * 1000))ms", file, function, line, column)
        }
        return try block()
    }

    static func logAppEvent(_ event: String,
                            _ file: String = #file,
                            _ function: String = #function,
                            _ line: Int = #line,
                            _ column: Int = #column) {
        info("📱 App Event: \(event)", file, function, line, column)
    }

    static func logUserAction(_ action: String,
                              _ file: String = #file,
                              _ function: String = #function,
                              _ line: Int = #line,
                              _ column: Int = #column) {
        info("👤 User Action: \(action)", file, function, line, column)
    }

    static func logNetworkRequest(_ endpoint: String,
                                 method: String,
                                 statusCode: Int? = nil,
                                 _ file: String = #file,
                                 _ function: String = #function,
                                 _ line: Int = #line,
                                 _ column: Int = #column) {
        let status = statusCode != nil ? " [\(statusCode!)]" : ""
        debug("🌐 \(method) \(endpoint)\(status)", file, function, line, column)
    }

    // MARK: - Private Methods
    private static func log(_ level: LogLevel,
                           _ message: @autoclosure () -> Any,
                           file: String,
                           function: String,
                           line: Int,
                           column: Int) {

        // Check if should log based on minimum level
        guard level.rawValue >= minimumLevel.rawValue else { return }

        let fileName = getFileName(from: file)
        let messageValue = String(describing: message())

        #if DEBUG
        // Build log message
        var logMessage = ""

        // Add timestamp
        if includeTimestamp {
            logMessage += "[\(Date())] "
        }

        // Add level emoji and name
        if enableColoredOutput {
            logMessage += "\(level.colorCode)\(level.emoji) \u{001B}[0m"
        } else {
            logMessage += "\(level.emoji) "
        }

        // Add file info
        logMessage += "[\(fileName)] "

        // Add function name and line
        logMessage += "\(function)() Line \(line) → "

        // Add message
        if enableColoredOutput {
            logMessage += "\(level.colorCode)\(messageValue)\u{001B}[0m"
        } else {
            logMessage += messageValue
        }

        print(logMessage)

        // Also persist a color-free line to the exportable debug log file so
        // Settings → "Share Log File" can hand it off for offline debugging.
        var fileLine = ""
        if includeTimestamp { fileLine += "[\(Date())] " }
        fileLine += "\(level.emoji) [\(fileName)] \(function)() Line \(line) → \(messageValue)"
        LogFileWriter.shared.append(fileLine)
        #else
        // Release: route warning/error to the unified log with PRIVATE
        // interpolation so dynamic content (file paths, URLs, IPs) is redacted
        // by the system instead of printed to stdout.
        osLog.log(level: level.osLogType, "[\(fileName, privacy: .public)] \(messageValue, privacy: .private)")
        #endif
    }

    #if !DEBUG
    private static let osLog = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "MusicApp", category: "app")
    #endif

    private static func getFileName(from path: String) -> String {
        let fileName = URL(fileURLWithPath: path).lastPathComponent
        if fileNameShortening {
            return fileName.components(separatedBy: ".").first ?? fileName
        }
        return fileName
    }
}

// MARK: - Global Convenience Functions
func LogV(_ message: @autoclosure () -> Any,
           _ file: String = #file,
           _ function: String = #function,
           _ line: Int = #line,
           _ column: Int = #column) {
    Logger.verbose(message(), file, function, line, column)
}

func LogD(_ message: @autoclosure () -> Any,
           _ file: String = #file,
           _ function: String = #function,
           _ line: Int = #line,
           _ column: Int = #column) {
    Logger.debug(message(), file, function, line, column)
}

func LogI(_ message: @autoclosure () -> Any,
           _ file: String = #file,
           _ function: String = #function,
           _ line: Int = #line,
           _ column: Int = #column) {
    Logger.info(message(), file, function, line, column)
}

func LogW(_ message: @autoclosure () -> Any,
           _ file: String = #file,
           _ function: String = #function,
           _ line: Int = #line,
           _ column: Int = #column) {
    Logger.warning(message(), file, function, line, column)
}

func LogE(_ message: @autoclosure () -> Any,
           _ file: String = #file,
           _ function: String = #function,
           _ line: Int = #line,
           _ column: Int = #column) {
    Logger.error(message(), file, function, line, column)
}

func LogE(_ error: Error,
           _ file: String = #file,
           _ function: String = #function,
           _ line: Int = #line,
           _ column: Int = #column) {
    Logger.error(error, file, function, line, column)
}