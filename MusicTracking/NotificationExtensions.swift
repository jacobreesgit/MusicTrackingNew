import Foundation

// MARK: - Notification Names

extension Notification.Name {
    
    // MARK: - App Lifecycle
    static let appDidBecomeActive = Notification.Name("com.jaba.MusicTracking.appDidBecomeActive")
    static let appWillResignActive = Notification.Name("com.jaba.MusicTracking.appWillResignActive")
    static let appDidEnterBackground = Notification.Name("com.jaba.MusicTracking.appDidEnterBackground")
    static let appWillEnterForeground = Notification.Name("com.jaba.MusicTracking.appWillEnterForeground")
    
    // MARK: - Music Tracking Events
    static let musicTrackingStarted = Notification.Name("com.jaba.MusicTracking.trackingStarted")
    static let musicTrackingStopped = Notification.Name("com.jaba.MusicTracking.trackingStopped")
    static let musicTrackingPaused = Notification.Name("com.jaba.MusicTracking.trackingPaused")
    static let musicTrackingResumed = Notification.Name("com.jaba.MusicTracking.trackingResumed")
    
    // MARK: - Song Events
    static let songDidStart = Notification.Name("com.jaba.MusicTracking.songDidStart")
    static let songDidEnd = Notification.Name("com.jaba.MusicTracking.songDidEnd")
    static let songDidPause = Notification.Name("com.jaba.MusicTracking.songDidPause")
    static let songDidResume = Notification.Name("com.jaba.MusicTracking.songDidResume")
    static let songDidSkip = Notification.Name("com.jaba.MusicTracking.songDidSkip")
    static let songDidSeek = Notification.Name("com.jaba.MusicTracking.songDidSeek")
    
    // MARK: - Listening Session Events
    static let sessionDidStart = Notification.Name("com.jaba.MusicTracking.sessionDidStart")
    static let sessionDidEnd = Notification.Name("com.jaba.MusicTracking.sessionDidEnd")
    static let sessionDidUpdate = Notification.Name("com.jaba.MusicTracking.sessionDidUpdate")
    static let sessionWasSaved = Notification.Name("com.jaba.MusicTracking.sessionWasSaved")
    
    // MARK: - Data Events
    static let dataDidSync = Notification.Name("com.jaba.MusicTracking.dataDidSync")
    static let dataDidFail = Notification.Name("com.jaba.MusicTracking.dataDidFail")
    static let dataDidReset = Notification.Name("com.jaba.MusicTracking.dataDidReset")
    static let dataDidExport = Notification.Name("com.jaba.MusicTracking.dataDidExport")
    static let dataDidImport = Notification.Name("com.jaba.MusicTracking.dataDidImport")
    
    // MARK: - Statistics Events
    static let statsDidUpdate = Notification.Name("com.jaba.MusicTracking.statsDidUpdate")
    static let weeklyStatsDidGenerate = Notification.Name("com.jaba.MusicTracking.weeklyStatsDidGenerate")
    static let monthlyStatsDidGenerate = Notification.Name("com.jaba.MusicTracking.monthlyStatsDidGenerate")
    
    // MARK: - Background Task Events
    static let backgroundTaskDidStart = Notification.Name("com.jaba.MusicTracking.backgroundTaskDidStart")
    static let backgroundTaskDidComplete = Notification.Name("com.jaba.MusicTracking.backgroundTaskDidComplete")
    static let backgroundTaskDidFail = Notification.Name("com.jaba.MusicTracking.backgroundTaskDidFail")
    static let backgroundTaskDidTimeout = Notification.Name("com.jaba.MusicTracking.backgroundTaskDidTimeout")
    
    // MARK: - Permission Events
    static let musicPermissionGranted = Notification.Name("com.jaba.MusicTracking.musicPermissionGranted")
    static let musicPermissionDenied = Notification.Name("com.jaba.MusicTracking.musicPermissionDenied")
    static let notificationPermissionGranted = Notification.Name("com.jaba.MusicTracking.notificationPermissionGranted")
    static let notificationPermissionDenied = Notification.Name("com.jaba.MusicTracking.notificationPermissionDenied")
    
    // MARK: - Error Events
    static let errorOccurred = Notification.Name("com.jaba.MusicTracking.errorOccurred")
    static let networkErrorOccurred = Notification.Name("com.jaba.MusicTracking.networkErrorOccurred")
    static let musicKitErrorOccurred = Notification.Name("com.jaba.MusicTracking.musicKitErrorOccurred")
    static let coreDataErrorOccurred = Notification.Name("com.jaba.MusicTracking.coreDataErrorOccurred")
    
    // MARK: - Settings Events
    static let settingsDidChange = Notification.Name("com.jaba.MusicTracking.settingsDidChange")
    static let privacySettingsDidChange = Notification.Name("com.jaba.MusicTracking.privacySettingsDidChange")
    static let trackingPreferencesDidChange = Notification.Name("com.jaba.MusicTracking.trackingPreferencesDidChange")
}

// MARK: - Notification Keys

struct NotificationKeys {
    
    // MARK: - General Keys
    static let userInfo = "userInfo"
    static let error = "error"
    static let timestamp = "timestamp"
    static let source = "source"
    static let reason = "reason"
    
    // MARK: - Song Keys
    static let songID = "songID"
    static let songTitle = "songTitle"
    static let artist = "artist"
    static let album = "album"
    static let duration = "duration"
    static let artwork = "artwork"
    static let genres = "genres"
    static let isExplicit = "isExplicit"
    static let playbackTime = "playbackTime"
    static let previousSongID = "previousSongID"
    
    // MARK: - Session Keys
    static let sessionID = "sessionID"
    static let sessionDuration = "sessionDuration"
    static let sessionStartTime = "sessionStartTime"
    static let sessionEndTime = "sessionEndTime"
    static let sessionSongCount = "sessionSongCount"
    static let sessionPlayCount = "sessionPlayCount"
    static let sessionSkipCount = "sessionSkipCount"
    static let sessionListeningTime = "sessionListeningTime"
    
    // MARK: - Statistics Keys
    static let totalPlayTime = "totalPlayTime"
    static let totalSessions = "totalSessions"
    static let totalSongs = "totalSongs"
    static let averageSessionDuration = "averageSessionDuration"
    static let topArtists = "topArtists"
    static let topSongs = "topSongs"
    static let topGenres = "topGenres"
    static let weekStartDate = "weekStartDate"
    static let monthYear = "monthYear"
    static let uniqueSongsCount = "uniqueSongsCount"
    static let mostActiveDay = "mostActiveDay"
    static let longestStreak = "longestStreak"
    
    // MARK: - Background Task Keys
    static let taskIdentifier = "taskIdentifier"
    static let taskType = "taskType"
    static let taskDuration = "taskDuration"
    static let taskRemainingTime = "taskRemainingTime"
    static let tasksProcessed = "tasksProcessed"
    static let tasksRemaining = "tasksRemaining"
    
    // MARK: - Data Keys
    static let recordCount = "recordCount"
    static let exportPath = "exportPath"
    static let importPath = "importPath"
    static let syncStatus = "syncStatus"
    static let cloudKitStatus = "cloudKitStatus"
    static let dataSize = "dataSize"
    static let backupDate = "backupDate"
    
    // MARK: - Error Keys
    static let errorCode = "errorCode"
    static let errorDomain = "errorDomain"
    static let errorDescription = "errorDescription"
    static let errorRecoverySuggestion = "errorRecoverySuggestion"
    static let errorCategory = "errorCategory"
    static let isRecoverable = "isRecoverable"
    static let shouldRetry = "shouldRetry"
    
    // MARK: - Settings Keys
    static let settingKey = "settingKey"
    static let oldValue = "oldValue"
    static let newValue = "newValue"
    static let isTrackingEnabled = "isTrackingEnabled"
    static let isBackgroundTrackingEnabled = "isBackgroundTrackingEnabled"
    static let isAnalyticsEnabled = "isAnalyticsEnabled"
    static let privacyLevel = "privacyLevel"
    
    // MARK: - Permission Keys
    static let permissionType = "permissionType"
    static let permissionStatus = "permissionStatus"
    static let authorizationStatus = "authorizationStatus"
}

// MARK: - Background Task Types

enum BackgroundTaskType: String, CaseIterable {
    case cleanup = "com.jaba.MusicTracking.cleanup"
    case statistics = "com.jaba.MusicTracking.stats"
    case monitoring = "com.jaba.MusicTracking.monitoring"
    case dataSync = "com.jaba.MusicTracking.dataSync"
    case export = "com.jaba.MusicTracking.export"
    
    var displayName: String {
        switch self {
        case .cleanup:
            return "Data Cleanup"
        case .statistics:
            return "Statistics Generation"
        case .monitoring:
            return "Music Monitoring"
        case .dataSync:
            return "Data Synchronization"
        case .export:
            return "Data Export"
        }
    }
}

// MARK: - Notification Helper

struct NotificationHelper {
    
    static func post(name: Notification.Name, userInfo: [String: Any]? = nil) {
        var info = userInfo ?? [:]
        info[NotificationKeys.timestamp] = Date()
        
        NotificationCenter.default.post(
            name: name,
            object: nil,
            userInfo: info
        )
    }
    
    static func postError(_ error: AppError, source: String? = nil) {
        var userInfo: [String: Any] = [
            NotificationKeys.error: error,
            NotificationKeys.errorCode: error.hashValue,
            NotificationKeys.errorDescription: error.localizedDescription,
            NotificationKeys.errorCategory: error.category.rawValue,
            NotificationKeys.isRecoverable: error.isRecoverable,
            NotificationKeys.shouldRetry: error.shouldRetry
        ]
        
        if let source = source {
            userInfo[NotificationKeys.source] = source
        }
        
        if let recoverySuggestion = error.recoverySuggestion {
            userInfo[NotificationKeys.errorRecoverySuggestion] = recoverySuggestion
        }
        
        post(name: .errorOccurred, userInfo: userInfo)
        
        // Post specific error type notifications
        switch error.category {
        case .network:
            post(name: .networkErrorOccurred, userInfo: userInfo)
        case .musicKit:
            post(name: .musicKitErrorOccurred, userInfo: userInfo)
        case .dataStorage:
            post(name: .coreDataErrorOccurred, userInfo: userInfo)
        default:
            break
        }
    }
    
    static func postSongEvent(
        _ notificationName: Notification.Name,
        songID: String,
        songTitle: String? = nil,
        artist: String? = nil,
        album: String? = nil,
        duration: TimeInterval? = nil,
        playbackTime: TimeInterval? = nil
    ) {
        var userInfo: [String: Any] = [
            NotificationKeys.songID: songID
        ]
        
        if let songTitle = songTitle {
            userInfo[NotificationKeys.songTitle] = songTitle
        }
        
        if let artist = artist {
            userInfo[NotificationKeys.artist] = artist
        }
        
        if let album = album {
            userInfo[NotificationKeys.album] = album
        }
        
        if let duration = duration {
            userInfo[NotificationKeys.duration] = duration
        }
        
        if let playbackTime = playbackTime {
            userInfo[NotificationKeys.playbackTime] = playbackTime
        }
        
        post(name: notificationName, userInfo: userInfo)
    }
    
    static func postSessionEvent(
        _ notificationName: Notification.Name,
        sessionID: UUID,
        duration: TimeInterval? = nil,
        songCount: Int? = nil,
        playCount: Int? = nil,
        skipCount: Int? = nil
    ) {
        var userInfo: [String: Any] = [
            NotificationKeys.sessionID: sessionID.uuidString
        ]
        
        if let duration = duration {
            userInfo[NotificationKeys.sessionDuration] = duration
        }
        
        if let songCount = songCount {
            userInfo[NotificationKeys.sessionSongCount] = songCount
        }
        
        if let playCount = playCount {
            userInfo[NotificationKeys.sessionPlayCount] = playCount
        }
        
        if let skipCount = skipCount {
            userInfo[NotificationKeys.sessionSkipCount] = skipCount
        }
        
        post(name: notificationName, userInfo: userInfo)
    }
    
    static func postBackgroundTaskEvent(
        _ notificationName: Notification.Name,
        taskType: BackgroundTaskType,
        duration: TimeInterval? = nil,
        remainingTime: TimeInterval? = nil
    ) {
        var userInfo: [String: Any] = [
            NotificationKeys.taskType: taskType.rawValue,
            NotificationKeys.taskIdentifier: taskType.displayName
        ]
        
        if let duration = duration {
            userInfo[NotificationKeys.taskDuration] = duration
        }
        
        if let remainingTime = remainingTime {
            userInfo[NotificationKeys.taskRemainingTime] = remainingTime
        }
        
        post(name: notificationName, userInfo: userInfo)
    }
    
    static func postSettingsChange(
        settingKey: String,
        oldValue: Any?,
        newValue: Any?
    ) {
        var userInfo: [String: Any] = [
            NotificationKeys.settingKey: settingKey
        ]
        
        if let oldValue = oldValue {
            userInfo[NotificationKeys.oldValue] = oldValue
        }
        
        if let newValue = newValue {
            userInfo[NotificationKeys.newValue] = newValue
        }
        
        post(name: .settingsDidChange, userInfo: userInfo)
    }
}

// MARK: - Notification Observer Helper

class NotificationObserver {
    private var observers: [NSObjectProtocol] = []
    
    deinit {
        removeAllObservers()
    }
    
    func observe(_ name: Notification.Name, using block: @escaping (Notification) -> Void) {
        let observer = NotificationCenter.default.addObserver(
            forName: name,
            object: nil,
            queue: .main,
            using: block
        )
        observers.append(observer)
    }
    
    func removeAllObservers() {
        observers.forEach { observer in
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
    }
}