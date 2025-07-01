import Foundation
import MediaPlayer
import BackgroundTasks
import AVFoundation
import UIKit

class BackgroundMusicMonitor: ObservableObject {
    static let shared = BackgroundMusicMonitor()
    
    // MARK: - Properties
    @Published private(set) var state = MonitoringState()
    @Published private(set) var isMonitoring = false
    @Published private(set) var currentTrack: MPMediaItem?
    @Published private(set) var playbackState: MPMusicPlaybackState = .stopped
    
    private let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    private let audioSessionManager = AudioSessionManager.shared
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    private var monitoringTimer: Timer?
    private var sessionStartTime: Date?
    private var lastTrackID: String?
    private var lastPlaybackTime: TimeInterval = 0
    private var playbackPositionTimer: Timer?
    
    // MARK: - Background Task Configuration
    private let backgroundTaskIdentifier = BackgroundTaskType.monitoring.rawValue
    private let maxBackgroundDuration: TimeInterval = 30.0 // iOS background limit
    private let monitoringInterval: TimeInterval = 1.0
    private let sessionGapThreshold: TimeInterval = 30.0 // Gap between songs to consider new session
    
    private init() {
        setupBackgroundTaskRegistration()
        setupNotificationObservers()
    }
    
    deinit {
        stopMonitoring()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        Task {
            do {
                try await requestMusicPermission()
                await MainActor.run {
                    setupMusicPlayerObservers()
                    startBackgroundTask()
                    isMonitoring = true
                    state.startSession()
                    
                    NotificationHelper.post(name: .musicTrackingStarted)
                    
                    // Start monitoring timer
                    monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
                        self?.updateTrackingState()
                    }
                }
            } catch {
                await MainActor.run {
                    let appError = AppError.from(musicKitError: error as! MusicKitError)
                    NotificationHelper.postError(appError, source: "BackgroundMusicMonitor")
                }
            }
        }
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        removeMusicPlayerObservers()
        stopBackgroundTask()
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        playbackPositionTimer?.invalidate()
        playbackPositionTimer = nil
        
        finalizeCurrentSession()
        
        isMonitoring = false
        state.endSession()
        
        NotificationHelper.post(name: .musicTrackingStopped)
    }
    
    func pauseMonitoring() {
        guard isMonitoring else { return }
        
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        playbackPositionTimer?.invalidate()
        playbackPositionTimer = nil
        
        state.pauseSession()
        NotificationHelper.post(name: .musicTrackingPaused)
    }
    
    func resumeMonitoring() {
        guard isMonitoring && state.isPaused else { return }
        
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            self?.updateTrackingState()
        }
        
        state.resumeSession()
        NotificationHelper.post(name: .musicTrackingResumed)
    }
    
    // MARK: - Private Methods
    
    private func setupBackgroundTaskRegistration() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { [weak self] task in
            self?.handleBackgroundTask(task as! BGProcessingTask)
        }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }
    
    private func setupMusicPlayerObservers() {
        musicPlayer.beginGeneratingPlaybackNotifications()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playbackStateChanged),
            name: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: musicPlayer
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(nowPlayingItemChanged),
            name: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: musicPlayer
        )
    }
    
    private func removeMusicPlayerObservers() {
        musicPlayer.endGeneratingPlaybackNotifications()
        
        NotificationCenter.default.removeObserver(
            self,
            name: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: musicPlayer
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: musicPlayer
        )
    }
    
    private func startBackgroundTask() {
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "MusicMonitoring") { [weak self] in
            self?.stopBackgroundTask()
        }
        
        NotificationHelper.postBackgroundTaskEvent(
            .backgroundTaskDidStart,
            taskType: .monitoring
        )
    }
    
    private func stopBackgroundTask() {
        guard backgroundTaskID != .invalid else { return }
        
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
        
        NotificationHelper.postBackgroundTaskEvent(
            .backgroundTaskDidComplete,
            taskType: .monitoring
        )
    }
    
    private func handleBackgroundTask(_ task: BGProcessingTask) {
        task.expirationHandler = {
            NotificationHelper.postBackgroundTaskEvent(
                .backgroundTaskDidTimeout,
                taskType: .monitoring
            )
            task.setTaskCompleted(success: false)
        }
        
        // Perform background monitoring
        Task {
            await performBackgroundMonitoring()
            task.setTaskCompleted(success: true)
        }
        
        // Schedule next background task
        scheduleBackgroundTask()
    }
    
    private func scheduleBackgroundTask() {
        let request = BGProcessingTaskRequest(identifier: backgroundTaskIdentifier)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            NotificationHelper.postError(
                .backgroundTaskRegistrationFailed,
                source: "BackgroundMusicMonitor"
            )
        }
    }
    
    private func performBackgroundMonitoring() async {
        await MainActor.run {
            updateTrackingState()
            
            // Perform any necessary cleanup or data processing
            if state.shouldProcessStats {
                processStatistics()
            }
            
            if state.shouldCleanupOldData {
                cleanupOldData()
            }
        }
    }
    
    private func updateTrackingState() {
        let currentPlaybackState = musicPlayer.playbackState
        let currentItem = musicPlayer.nowPlayingItem
        let currentTime = musicPlayer.currentPlaybackTime
        
        // Update playback state
        if playbackState != currentPlaybackState {
            playbackState = currentPlaybackState
            handlePlaybackStateChange(currentPlaybackState)
        }
        
        // Update current track
        if currentTrack != currentItem {
            handleTrackChange(from: currentTrack, to: currentItem)
            currentTrack = currentItem
        }
        
        // Update playback position for current track
        if playbackState == .playing, let item = currentItem {
            handlePlaybackProgress(item: item, currentTime: currentTime)
        }
        
        // Update state metrics
        state.updateMetrics(
            isPlaying: playbackState == .playing,
            currentTrack: currentItem,
            playbackTime: currentTime
        )
    }
    
    private func handlePlaybackStateChange(_ newState: MPMusicPlaybackState) {
        switch newState {
        case .playing:
            if sessionStartTime == nil {
                startNewSession()
            }
            startPlaybackPositionTimer()
            NotificationHelper.post(name: .songDidResume)
            
        case .paused:
            stopPlaybackPositionTimer()
            NotificationHelper.post(name: .songDidPause)
            
        case .stopped:
            stopPlaybackPositionTimer()
            finalizeCurrentSession()
            NotificationHelper.post(name: .songDidEnd)
            
        case .interrupted:
            stopPlaybackPositionTimer()
            
        case .seekingForward, .seekingBackward:
            NotificationHelper.post(name: .songDidSeek)
            
        @unknown default:
            break
        }
    }
    
    private func handleTrackChange(from previousItem: MPMediaItem?, to currentItem: MPMediaItem?) {
        // Finalize previous track if exists
        if let previousItem = previousItem {
            finalizeTrackPlayback(previousItem)
        }
        
        // Start tracking new item
        if let currentItem = currentItem {
            startTrackPlayback(currentItem)
        } else {
            // No current item - music stopped
            finalizeCurrentSession()
        }
    }
    
    private func startTrackPlayback(_ item: MPMediaItem) {
        let trackID = item.persistentID.description
        lastTrackID = trackID
        lastPlaybackTime = 0
        
        // Check if this is a new session
        if sessionStartTime == nil || 
           Date().timeIntervalSince(sessionStartTime ?? Date()) > sessionGapThreshold {
            startNewSession()
        }
        
        state.startTrack(item)
        
        NotificationHelper.postSongEvent(
            .songDidStart,
            songID: trackID,
            songTitle: item.title,
            artist: item.artist,
            album: item.albumTitle,
            duration: item.playbackDuration
        )
    }
    
    private func finalizeTrackPlayback(_ item: MPMediaItem) {
        let trackID = item.persistentID.description
        let finalPlaybackTime = musicPlayer.currentPlaybackTime
        
        // Determine if track was skipped
        let wasSkipped = finalPlaybackTime < item.playbackDuration * 0.8 // Consider skipped if less than 80% played
        
        state.endTrack(item, wasSkipped: wasSkipped, finalTime: finalPlaybackTime)
        
        if wasSkipped {
            NotificationHelper.postSongEvent(
                .songDidSkip,
                songID: trackID,
                songTitle: item.title,
                artist: item.artist,
                playbackTime: finalPlaybackTime
            )
        } else {
            NotificationHelper.postSongEvent(
                .songDidEnd,
                songID: trackID,
                songTitle: item.title,
                artist: item.artist,
                playbackTime: finalPlaybackTime
            )
        }
    }
    
    private func handlePlaybackProgress(item: MPMediaItem, currentTime: TimeInterval) {
        let trackID = item.persistentID.description
        
        // Update only if significant progress (avoid too frequent updates)
        if abs(currentTime - lastPlaybackTime) >= 1.0 {
            lastPlaybackTime = currentTime
            state.updatePlaybackProgress(item, currentTime: currentTime)
        }
    }
    
    private func startNewSession() {
        sessionStartTime = Date()
        state.startNewSession()
        
        NotificationHelper.postSessionEvent(
            .sessionDidStart,
            sessionID: state.currentSessionID
        )
    }
    
    private func finalizeCurrentSession() {
        guard let startTime = sessionStartTime else { return }
        
        let sessionDuration = Date().timeIntervalSince(startTime)
        sessionStartTime = nil
        
        let sessionData = state.finalizeSession(duration: sessionDuration)
        
        NotificationHelper.postSessionEvent(
            .sessionDidEnd,
            sessionID: sessionData.id,
            duration: sessionDuration,
            songCount: sessionData.songCount,
            playCount: sessionData.playCount,
            skipCount: sessionData.skipCount
        )
        
        // Save session to Core Data
        saveSessionData(sessionData)
    }
    
    private func startPlaybackPositionTimer() {
        playbackPositionTimer?.invalidate()
        playbackPositionTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self,
                  let currentItem = self.currentTrack,
                  self.playbackState == .playing else { return }
            
            let currentTime = self.musicPlayer.currentPlaybackTime
            self.handlePlaybackProgress(item: currentItem, currentTime: currentTime)
        }
    }
    
    private func stopPlaybackPositionTimer() {
        playbackPositionTimer?.invalidate()
        playbackPositionTimer = nil
    }
    
    private func saveSessionData(_ sessionData: SessionData) {
        Task {
            do {
                // This would integrate with your Core Data persistence layer
                // For now, just post notification that session was saved
                NotificationHelper.postSessionEvent(
                    .sessionWasSaved,
                    sessionID: sessionData.id,
                    duration: sessionData.duration,
                    songCount: sessionData.songCount
                )
            } catch {
                NotificationHelper.postError(
                    AppError.coreDataSaveFailed(error.localizedDescription),
                    source: "BackgroundMusicMonitor"
                )
            }
        }
    }
    
    private func processStatistics() {
        // Process weekly/monthly statistics
        state.processStatistics()
        NotificationHelper.post(name: .statsDidUpdate)
    }
    
    private func cleanupOldData() {
        // Clean up old session data based on retention policy
        state.cleanupOldData()
    }
    
    private func requestMusicPermission() async throws {
        let status = MPMediaLibrary.authorizationStatus()
        
        switch status {
        case .authorized:
            NotificationHelper.post(name: .musicPermissionGranted)
            return
            
        case .notDetermined:
            return try await withCheckedThrowingContinuation { continuation in
                MPMediaLibrary.requestAuthorization { newStatus in
                    switch newStatus {
                    case .authorized:
                        NotificationHelper.post(name: .musicPermissionGranted)
                        continuation.resume()
                    case .denied, .restricted:
                        NotificationHelper.post(name: .musicPermissionDenied)
                        continuation.resume(throwing: AppError.musicKitUnauthorized)
                    default:
                        continuation.resume(throwing: AppError.musicKitUnauthorized)
                    }
                }
            }
            
        case .denied, .restricted:
            NotificationHelper.post(name: .musicPermissionDenied)
            throw AppError.musicKitUnauthorized
            
        @unknown default:
            throw AppError.musicKitNotSupported
        }
    }
    
    // MARK: - Notification Handlers
    
    @objc private func appDidEnterBackground() {
        guard isMonitoring else { return }
        
        // Configure audio session for background monitoring
        audioSessionManager.configureForBackgroundMonitoring()
        
        // Start background task
        startBackgroundTask()
        
        // Schedule background processing
        scheduleBackgroundTask()
        
        NotificationHelper.post(name: .appDidEnterBackground)
    }
    
    @objc private func appWillEnterForeground() {
        guard isMonitoring else { return }
        
        // Restore audio session for foreground
        audioSessionManager.configureForForegroundMonitoring()
        
        // Stop background task
        stopBackgroundTask()
        
        NotificationHelper.post(name: .appWillEnterForeground)
    }
    
    @objc private func playbackStateChanged() {
        updateTrackingState()
    }
    
    @objc private func nowPlayingItemChanged() {
        updateTrackingState()
    }
    
    @objc private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Audio session interrupted - pause monitoring
            pauseMonitoring()
            
        case .ended:
            // Audio session resumed - check if should resume monitoring
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    resumeMonitoring()
                }
            }
            
        @unknown default:
            break
        }
    }
    
    @objc private func handleAudioSessionRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            // Headphones unplugged, etc. - might need to pause monitoring
            if playbackState == .playing {
                // Let the system handle this naturally through playback state changes
            }
            
        default:
            break
        }
    }
}

// MARK: - Session Data Structure

struct SessionData {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let songCount: Int
    let playCount: Int
    let skipCount: Int
    let totalListeningTime: TimeInterval
    let tracks: [TrackData]
}

struct TrackData {
    let id: String
    let title: String?
    let artist: String?
    let album: String?
    let duration: TimeInterval
    let playbackTime: TimeInterval
    let wasSkipped: Bool
    let timestamp: Date
}