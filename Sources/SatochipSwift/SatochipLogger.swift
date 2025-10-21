//
//  SatochipLogger.swift
//  SatochipSwift
//
//  Created by Satochip on 2024.
//

import Foundation
import os.log

/// Centralized logging system for SatochipSwift library
public class SatochipLogger {
    
    /// Shared logger instance
    public static let shared = SatochipLogger()
    
    /// Logging subsystem for SatochipSwift
    private static let subsystem = "com.satochip.SatochipSwift"
    
    /// Log categories for different components
    public enum Category: String, CaseIterable {
        case general = "General"
        case cardChannel = "CardChannel"
        case commandSet = "CommandSet"
        case controller = "Controller"
        case parser = "Parser"
        case crypto = "Crypto"
        case secureChannel = "SecureChannel"
        case seedkeeper = "Seedkeeper"
        case satodime = "Satodime"
        case nfc = "NFC"
    }
    
    /// Log levels
    public enum Level: String, CaseIterable {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case fault = "FAULT"
    }
    
    /// Logging configuration
    public struct Configuration {
        public var isEnabled: Bool = true
        public var minimumLevel: Level = .info
        public var includeTimestamp: Bool = true
        public var includeCategory: Bool = true
        public var includeLevel: Bool = true
        public var logToConsole: Bool = true
        public var logToOSLog: Bool = true
        
        public init() {}
    }
    
    /// Current configuration
    public var configuration = Configuration()
    
    /// Log instances for each category
    private var loggers: [Category: OSLog] = [:]
    
    private init() {
        setupLoggers()
    }
    
    /// Setup loggers for each category
    private func setupLoggers() {
        for category in Category.allCases {
            loggers[category] = OSLog(subsystem: SatochipLogger.subsystem, category: category.rawValue)
        }
    }
    
    /// Configure logging
    public func configure(_ config: Configuration) {
        configuration = config
    }
    
    /// Log a message
    public func log(_ message: String, 
                   level: Level = .info, 
                   category: Category = .general, 
                   file: String = #file, 
                   function: String = #function, 
                   line: Int = #line) {
        
        guard configuration.isEnabled else { return }
        
        // Check if we should log this level
        guard shouldLog(level: level) else { return }
        
        let formattedMessage = formatMessage(message, level: level, category: category, file: file, function: function, line: line)
        
        // Log to console if enabled
        if configuration.logToConsole {
            print(formattedMessage)
        }
        
        // Log to OSLog if enabled
        if configuration.logToOSLog, let logger = loggers[category] {
            let osLogType = osLogType(for: level)
            os_log("%{public}@", log: logger, type: osLogType, formattedMessage)
        }
    }
    
    /// Check if we should log at this level
    private func shouldLog(level: Level) -> Bool {
        let levelOrder: [Level] = [.debug, .info, .warning, .error, .fault]
        guard let currentIndex = levelOrder.firstIndex(of: configuration.minimumLevel),
              let messageIndex = levelOrder.firstIndex(of: level) else {
            return false
        }
        return messageIndex >= currentIndex
    }
    
    /// Format the log message
    private func formatMessage(_ message: String, 
                              level: Level, 
                              category: Category, 
                              file: String, 
                              function: String, 
                              line: Int) -> String {
        
        var components: [String] = []
        
        if configuration.includeTimestamp {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            components.append("[\(formatter.string(from: Date()))]")
        }
        
        if configuration.includeLevel {
            components.append("[\(level.rawValue)]")
        }
        
        if configuration.includeCategory {
            components.append("[\(category.rawValue)]")
        }
        
        // Add file and function info for debug level
        if level == .debug {
            let fileName = URL(fileURLWithPath: file).lastPathComponent
            components.append("[\(fileName):\(function):\(line)]")
        }
        
        components.append(message)
        
        return components.joined(separator: " ")
    }
    
    /// Convert our log level to OSLog type
    private func osLogType(for level: Level) -> OSLogType {
        switch level {
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .default
        case .error:
            return .error
        case .fault:
            return .fault
        }
    }
    
    // MARK: - Convenience Methods
    
    public func debug(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }
    
    public func info(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    public func warning(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    public func error(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
    
    public func fault(_ message: String, category: Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .fault, category: category, file: file, function: function, line: line)
    }
}

// MARK: - Global Logging Functions

/// Global logging functions for easy access
public func SatochipLog(_ message: String, level: SatochipLogger.Level = .info, category: SatochipLogger.Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
    SatochipLogger.shared.log(message, level: level, category: category, file: file, function: function, line: line)
}

public func SatochipDebug(_ message: String, category: SatochipLogger.Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
    SatochipLogger.shared.debug(message, category: category, file: file, function: function, line: line)
}

public func SatochipInfo(_ message: String, category: SatochipLogger.Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
    SatochipLogger.shared.info(message, category: category, file: file, function: function, line: line)
}

public func SatochipWarning(_ message: String, category: SatochipLogger.Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
    SatochipLogger.shared.warning(message, category: category, file: file, function: function, line: line)
}

public func SatochipError(_ message: String, category: SatochipLogger.Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
    SatochipLogger.shared.error(message, category: category, file: file, function: function, line: line)
}

public func SatochipFault(_ message: String, category: SatochipLogger.Category = .general, file: String = #file, function: String = #function, line: Int = #line) {
    SatochipLogger.shared.fault(message, category: category, file: file, function: function, line: line)
}
