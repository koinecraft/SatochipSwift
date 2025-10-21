//
//  LoggingConfiguration.swift
//  SatochipSwift
//
//  Created by Satochip on 2024.
//

import Foundation

/// Configuration helper for SatochipSwift logging
public class LoggingConfiguration {
    
    /// Configure SatochipSwift logging for different environments
    public static func configureForDevelopment() {
        var config = SatochipLogger.Configuration()
        config.isEnabled = true
        config.minimumLevel = .debug
        config.includeTimestamp = true
        config.includeCategory = true
        config.includeLevel = true
        config.logToConsole = true
        config.logToOSLog = true
        
        SatochipLogger.shared.configure(config)
    }
    
    /// Configure SatochipSwift logging for production
    public static func configureForProduction() {
        var config = SatochipLogger.Configuration()
        config.isEnabled = true
        config.minimumLevel = .warning
        config.includeTimestamp = true
        config.includeCategory = true
        config.includeLevel = true
        config.logToConsole = false
        config.logToOSLog = true
        
        SatochipLogger.shared.configure(config)
    }
    
    /// Configure SatochipSwift logging for testing
    public static func configureForTesting() {
        var config = SatochipLogger.Configuration()
        config.isEnabled = true
        config.minimumLevel = .info
        config.includeTimestamp = false
        config.includeCategory = false
        config.includeLevel = false
        config.logToConsole = true
        config.logToOSLog = false
        
        SatochipLogger.shared.configure(config)
    }
    
    /// Disable all SatochipSwift logging
    public static func disableLogging() {
        var config = SatochipLogger.Configuration()
        config.isEnabled = false
        SatochipLogger.shared.configure(config)
    }
    
    /// Enable logging for specific categories only
    public static func enableForCategories(_ categories: [SatochipLogger.Category]) {
        // Note: This is a simplified example. In a full implementation,
        // you might want to add category-specific filtering to the logger
        var config = SatochipLogger.Configuration()
        config.isEnabled = true
        config.minimumLevel = .debug
        config.includeTimestamp = true
        config.includeCategory = true
        config.includeLevel = true
        config.logToConsole = true
        config.logToOSLog = true
        
        SatochipLogger.shared.configure(config)
    }
}
