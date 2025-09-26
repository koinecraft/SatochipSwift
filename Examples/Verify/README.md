# Verify iOS App

A simple iOS application that demonstrates basic UI functionality with a text view and button.

## Features

- Single screen with a text view for logging messages
- "Verify" button that appends "Verified" messages with timestamps
- Auto-scrolling to show the most recent message
- Clean, modern UI with proper constraints

## Usage

1. Launch the app
2. Tap the "Verify" button to add a new verification message
3. Each tap adds a timestamped "Verified" message to the text view
4. The text view automatically scrolls to show the latest message

## Technical Details

- Built with UIKit and programmatic UI
- Uses Auto Layout constraints for responsive design
- Implements proper iOS app lifecycle management
- Compatible with iOS 13.0 and later

## Project Structure

- `ViewController.swift` - Main view controller with UI logic
- `AppDelegate.swift` - App lifecycle management
- `SceneDelegate.swift` - Scene lifecycle management
- `Info.plist` - App configuration
- `Verify.entitlements` - App entitlements
- `Assets.xcassets` - App icons and colors
- `Base.lproj/` - Storyboard files
