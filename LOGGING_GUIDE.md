# SatochipSwift Logging Guide

This guide explains how to use the logging system in SatochipSwift library to help with debugging and monitoring in your applications.

## Overview

SatochipSwift includes a comprehensive logging system that allows you to:
- See detailed logs in Xcode console
- Configure different log levels for different environments
- Filter logs by category (CardChannel, CommandSet, Controller, etc.)
- Control whether logs appear in console, OSLog, or both

## Quick Start

### 1. Configure Logging in Your App

Add this to your `AppDelegate.swift` or main app file:

```swift
import SatochipSwift

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Configure logging for development
    LoggingConfiguration.configureForDevelopment()
    
    return true
}
```

### 2. View Logs in Xcode

Once configured, you'll see SatochipSwift logs in the Xcode console with timestamps, categories, and log levels:

```
[2024-01-15 10:30:45.123] [DEBUG] [CommandSet] Getting extended key for path: m/44'/0'/0'/0/0
[2024-01-15 10:30:45.124] [DEBUG] [CardChannel] APDU Command: cla=0x00 ins=0xE0 p1=0x00 p2=0x00 lc=0
[2024-01-15 10:30:45.125] [DEBUG] [CardChannel] APDU Response: data len=32 sw=0x9000
```

## Configuration Options

### Pre-configured Environments

#### Development
```swift
LoggingConfiguration.configureForDevelopment()
```
- Shows all log levels (DEBUG, INFO, WARNING, ERROR, FAULT)
- Includes timestamps, categories, and log levels
- Logs to both console and OSLog
- Best for debugging during development

#### Production
```swift
LoggingConfiguration.configureForProduction()
```
- Shows only WARNING, ERROR, and FAULT levels
- Includes timestamps and categories
- Logs only to OSLog (not console)
- Best for production apps

#### Testing
```swift
LoggingConfiguration.configureForTesting()
```
- Shows INFO level and above
- Minimal formatting
- Logs only to console
- Best for unit tests

#### Disable Logging
```swift
LoggingConfiguration.disableLogging()
```
- Completely disables SatochipSwift logging
- Use when you don't want any logs

### Custom Configuration

You can also create custom configurations:

```swift
var config = SatochipLogger.Configuration()
config.isEnabled = true
config.minimumLevel = .info
config.includeTimestamp = true
config.includeCategory = true
config.includeLevel = true
config.logToConsole = true
config.logToOSLog = true

SatochipLogger.shared.configure(config)
```

## Log Categories

SatochipSwift logs are organized by category to help you filter and understand what's happening:

- **General**: General library operations
- **CardChannel**: NFC communication and APDU commands
- **CommandSet**: Card command execution
- **Controller**: Card controller operations
- **Parser**: Data parsing operations
- **Crypto**: Cryptographic operations
- **SecureChannel**: Secure channel establishment
- **Seedkeeper**: Seedkeeper operations
- **Satodime**: Satodime operations
- **NFC**: NFC-specific operations

## Log Levels

- **DEBUG**: Detailed information for debugging (most verbose)
- **INFO**: General information about operations
- **WARNING**: Warning messages about potential issues
- **ERROR**: Error conditions that don't stop execution
- **FAULT**: Critical errors that may cause failures

## Using Logs for Debugging

### Common Debugging Scenarios

#### 1. NFC Connection Issues
Look for logs with category `CardChannel` or `NFC`:
```
[DEBUG] [CardChannel] APDU Command: cla=0x00 ins=0xE0 p1=0x00 p2=0x00 lc=0
[ERROR] [CardChannel] CardChannel error: NFC connection lost
```

#### 2. Card Command Failures
Look for logs with category `CommandSet`:
```
[DEBUG] [CommandSet] Getting extended key for path: m/44'/0'/0'/0/0
[ERROR] [CommandSet] PIN blocked
```

#### 3. Secure Channel Issues
Look for logs with category `SecureChannel`:
```
[DEBUG] [SecureChannel] Establishing secure channel
[WARNING] [SecureChannel] Authentication failed, retrying...
```

### Filtering Logs in Xcode

You can filter logs in Xcode console:

1. **By Category**: Search for `[CommandSet]` or `[CardChannel]`
2. **By Level**: Search for `[ERROR]` or `[WARNING]`
3. **By Function**: Search for specific function names

### Using Console.app

For production apps, you can also view logs in Console.app:

1. Open Console.app
2. Select your device or simulator
3. Search for "com.satochip.SatochipSwift"
4. Filter by category or level as needed

## Performance Considerations

- **Development**: Use `configureForDevelopment()` for maximum visibility
- **Production**: Use `configureForProduction()` to minimize performance impact
- **Testing**: Use `configureForTesting()` for clean test output

## Troubleshooting

### No Logs Appearing
1. Check that logging is enabled: `config.isEnabled = true`
2. Verify minimum log level is set appropriately
3. Ensure you're looking in the right place (Xcode console vs Console.app)

### Too Many Logs
1. Increase minimum log level (e.g., from `.debug` to `.info`)
2. Disable console logging: `config.logToConsole = false`
3. Use production configuration

### Missing Specific Information
1. Check if the log level is high enough
2. Verify the category is being logged
3. Consider using custom logging in your app code

## Example Integration

Here's a complete example of how to integrate SatochipSwift logging in your app:

```swift
import UIKit
import SatochipSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        #if DEBUG
        // Enable detailed logging for development
        LoggingConfiguration.configureForDevelopment()
        #else
        // Use production logging for release builds
        LoggingConfiguration.configureForProduction()
        #endif
        
        return true
    }
}
```

This setup will automatically show SatochipSwift logs in your Xcode console, making it much easier to debug NFC and card communication issues.
