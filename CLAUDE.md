# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Swift/SwiftUI iOS application called "MusicTracking" that uses Core Data with CloudKit integration for data persistence. The app appears to be a basic template with Item entities that have timestamps, likely intended for tracking music-related data.

## Architecture

- **App Structure**: Standard SwiftUI app with `MusicTrackingApp.swift` as the main entry point
- **Data Layer**: Core Data with CloudKit sync via `NSPersistentCloudKitContainer`
- **UI Layer**: SwiftUI views with `ContentView.swift` as the main interface
- **Data Model**: Single `Item` entity with timestamp attribute defined in `MusicTracking.xcdatamodeld`
- **Persistence**: Managed through `PersistenceController` singleton with shared and preview contexts

## Key Components

- `MusicTrackingApp.swift`: Main app entry point, sets up Core Data environment
- `ContentView.swift`: Primary UI with list view, add/delete functionality for items
- `Persistence.swift`: Core Data stack configuration with CloudKit integration
- `MusicTracking.xcdatamodeld`: Core Data model defining Item entity

## Development Commands

### Building
```bash
# Build for iOS simulator (iPhone 16)
xcodebuild -project MusicTracking.xcodeproj -scheme MusicTracking -destination 'platform=iOS Simulator,name=iPhone 16' build

# Build for macOS (if supported)
xcodebuild -project MusicTracking.xcodeproj -scheme MusicTracking build
```

### Running
```bash
# Build and run on iOS simulator
xcodebuild -project MusicTracking.xcodeproj -scheme MusicTracking -destination 'platform=iOS Simulator,name=iPhone 16' build run

# Or use Xcode GUI to run on device/simulator
```

### Testing
```bash
# Run tests (if any exist)
xcodebuild -project MusicTracking.xcodeproj -scheme MusicTracking -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Data Model Notes

The Core Data model is configured for CloudKit synchronization. The `Item` entity has:
- `timestamp` attribute (Date, optional)
- Configured for CloudKit sync with `usedWithCloudKit="true"`

## Development Notes

- The app uses `fatalError()` for error handling in development - this should be replaced with proper error handling for production
- CloudKit integration is enabled, requiring proper entitlements and CloudKit container setup
- The preview context creates 10 sample items for SwiftUI previews