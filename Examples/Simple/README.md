# Simple Example

This is a simple iOS example project that demonstrates the basic structure for integrating with the SatochipSwift SDK.

## Overview

The Simple example provides a basic iOS app with a single screen containing:

- **Message Input**: A multiline text view where users can enter messages to be signed
- **Processed Messages**: A multiline text view that displays the results of message processing
- **Clear Button**: Clears both text views and resets them to their placeholder state
- **Sign Button**: Processes the input message (currently shows placeholder functionality)

## Features

- Clean, modern UI with Auto Layout constraints
- Placeholder text handling for better user experience
- Basic input validation
- Timestamped message processing
- NFC permissions configured for Satochip integration

## Project Structure

```
Simple/
├── Simple.xcodeproj/          # Xcode project file
├── Simple/                    # Source code directory
│   ├── AppDelegate.swift      # App lifecycle management
│   ├── SceneDelegate.swift    # Scene lifecycle management
│   ├── ViewController.swift   # Main view controller with UI
│   ├── Base.lproj/           # Localized resources
│   │   ├── Main.storyboard   # Main app interface
│   │   └── LaunchScreen.storyboard # Launch screen
│   ├── Assets.xcassets/      # App icons and colors
│   └── Info.plist           # App configuration
└── README.md                # This file
```

## Getting Started

1. Open `Simple.xcodeproj` in Xcode
2. Select your target device or simulator
3. Build and run the project (⌘+R)

## Next Steps

This example provides the foundation for integrating Satochip functionality. To add actual Satochip integration:

1. Add the SatochipSwift package dependency
2. Implement NFC tag reading in the ViewController
3. Add Satochip card communication logic
4. Implement actual message signing functionality

## Requirements

- iOS 13.0+
- Xcode 15.0+
- Device with NFC capability (for Satochip integration)

## Notes

- The app currently shows placeholder functionality for message signing
- NFC permissions are pre-configured in Info.plist
- The UI is designed to be responsive and user-friendly
- All text views include placeholder text handling for better UX
