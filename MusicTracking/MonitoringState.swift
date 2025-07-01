import Foundation
import MediaPlayer

class MonitoringState: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var isActive = false
    @Published private(set) var isPaused = false
    @Published private(set) var currentSessionID = UUID()
    @Published private(set) var sessionStartTime: Date?
    @Published private(set) var sessionDuration: TimeInterval = 0
    @Published private(set) var currentTrackInfo: TrackInfo?
    @Published private(set) var sessionMetrics = SessionMetrics()
    @Published private(set) var overallMetrics = OverallMetrics()
    
    // MARK: - Private Properties
    private var sessionTracks: [TrackPlayback] = []
    private var currentTrackPlayback: TrackPlayback?
    private var metricsTimer: Timer?
    private var lastStatsProcessTime: Date?
    private var lastCleanupTime: Date?
    
    // MARK: - Configuration
    private let statsProcessingInterval: TimeInterval = 3600 // 1 hour
    private let dataCleanupInterval: TimeInterval = 86400 // 24 hours
    private let maxSessionGap: TimeInterval = 1800 // 30 minutes
    private let minValidPlaybackTime: TimeInterval = 10 // 10 seconds minimum
    
    init() {
        setupMetricsTimer()
    }
    
    deinit {
        metricsTimer?.invalidate()
    }
    
    // MARK: - Session Management
    
    func startSession() {
        isActive = true
        isPaused = false
        currentSessionID = UUID()
        sessionStartTime = Date()
        sessionDuration = 0
        sessionTracks.removeAll()
        currentTrackPlayback = nil
        sessionMetrics.reset()
        
        startMetricsTimer()
        
        overallMetrics.totalSessions += 1
        overallMetrics.lastSessionDate = Date()
    }
    
    func endSession() {
        finalizeCurrentTrack()
        
        let endTime = Date()
        if let startTime = sessionStartTime {
            sessionDuration = endTime.timeIntervalSince(startTime)
        }
        
        isActive = false
        isPaused = false
        stopMetricsTimer()
        
        // Update overall metrics
        overallMetrics.totalPlayTime += sessionMetrics.totalListeningTime
        overallMetrics.updateWithSession(sessionMetrics)
    }
    
    func pauseSession() {
        guard isActive && !isPaused else { return }
        
        isPaused = true
        finalizeCurrentTrack()
        stopMetricsTimer()
    }
    
    func resumeSession() {
        guard isActive && isPaused else { return }
        
        isPaused = false
        startMetricsTimer()
    }
    
    func startNewSession() {
        if isActive {
            endSession()
        }
        startSession()
    }
    
    // MARK: - Track Management
    
    func startTrack(_ item: MPMediaItem) {
        finalizeCurrentTrack()
        
        let trackInfo = TrackInfo(from: item)
        currentTrackInfo = trackInfo
        
        currentTrackPlayback = TrackPlayback(
            trackInfo: trackInfo,
            startTime: Date()
        )
        
        sessionMetrics.currentTrackCount += 1
        sessionMetrics.totalTracks += 1
    }
    
    func endTrack(_ item: MPMediaItem, wasSkipped: Bool, finalTime: TimeInterval) {
        guard let playback = currentTrackPlayback else { return }
        
        playback.endTime = Date()
        playback.totalPlayTime = finalTime
        playback.wasSkipped = wasSkipped
        playback.isComplete = !wasSkipped && finalTime >= (item.playbackDuration * 0.8)
        
        finalizeCurrentTrack()
        
        if wasSkipped {
            sessionMetrics.skippedTracks += 1
        } else {
            sessionMetrics.completedTracks += 1
        }
    }
    
    func updatePlaybackProgress(_ item: MPMediaItem, currentTime: TimeInterval) {
        guard let playback = currentTrackPlayback else { return }
        
        playback.lastKnownPosition = currentTime
        playback.lastUpdateTime = Date()
        
        // Update listening time for track
        let listeningTime = min(currentTime, item.playbackDuration)
        playback.listeningTime = listeningTime
        
        // Update session metrics
        updateSessionListeningTime()
    }
    
    private func finalizeCurrentTrack() {
        guard let playback = currentTrackPlayback else { return }
        
        if playback.endTime == nil {
            playback.endTime = Date()
        }
        
        // Calculate final listening time
        if let startTime = playback.startTime, let endTime = playback.endTime {
            let actualDuration = endTime.timeIntervalSince(startTime)
            playback.actualDuration = actualDuration
        }
        
        sessionTracks.append(playback)
        currentTrackPlayback = nil
        currentTrackInfo = nil
    }
    
    // MARK: - Metrics Updates
    
    func updateMetrics(isPlaying: Bool, currentTrack: MPMediaItem?, playbackTime: TimeInterval) {
        if isPlaying, let track = currentTrack {
            updatePlaybackProgress(track, currentTime: playbackTime)
        }
        
        updateSessionDuration()
        updateOverallMetrics()
    }
    
    private func updateSessionDuration() {
        guard let startTime = sessionStartTime else { return }
        sessionDuration = Date().timeIntervalSince(startTime)
    }
    
    private func updateSessionListeningTime() {
        let totalListening = sessionTracks.reduce(0) { $0 + $1.listeningTime }
        let currentListening = currentTrackPlayback?.listeningTime ?? 0
        sessionMetrics.totalListeningTime = totalListening + currentListening
    }
    
    private func updateOverallMetrics() {
        overallMetrics.currentSessionDuration = sessionDuration
        overallMetrics.currentSessionListeningTime = sessionMetrics.totalListeningTime
        
        // Update streak information
        updateStreakMetrics()
    }
    
    private func updateStreakMetrics() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if !Calendar.current.isDate(overallMetrics.lastActiveDate, inSameDayAs: today) {
            if Calendar.current.isDate(overallMetrics.lastActiveDate, inSameDayAs: Calendar.current.date(byAdding: .day, value: -1, to: today)!) {
                // Yesterday was last active day - continue streak
                overallMetrics.currentStreak += 1
            } else {
                // Gap in activity - reset streak
                overallMetrics.currentStreak = 1
            }
            
            overallMetrics.lastActiveDate = today
            
            if overallMetrics.currentStreak > overallMetrics.longestStreak {
                overallMetrics.longestStreak = overallMetrics.currentStreak
            }
        }
    }
    
    // MARK: - Statistics Processing
    
    func processStatistics() {
        let now = Date()
        
        // Process weekly statistics
        processWeeklyStatistics()
        
        // Process monthly statistics
        processMonthlyStatistics()
        
        lastStatsProcessTime = now
    }
    
    private func processWeeklyStatistics() {
        let weekStart = DateUtilities.shared.startOfWeek()
        let weeklyStats = generateWeeklyStats(for: weekStart)
        
        // This would typically save to Core Data
        overallMetrics.weeklyStats = weeklyStats
    }
    
    private func processMonthlyStatistics() {
        let monthStart = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
        let monthlyStats = generateMonthlyStats(for: monthStart)
        
        // This would typically save to Core Data
        overallMetrics.monthlyStats = monthlyStats
    }
    
    private func generateWeeklyStats(for weekStart: Date) -> WeeklyStats {
        // This would query Core Data for the week's sessions
        // For now, return current session data
        return WeeklyStats(
            weekStartDate: weekStart,
            totalSessions: sessionMetrics.totalTracks > 0 ? 1 : 0,
            totalPlayTime: sessionMetrics.totalListeningTime,
            uniqueSongsCount: sessionTracks.count,
            averageSessionDuration: sessionDuration,
            mostActiveDay: DateUtilities.weekdayFormatter.string(from: Date()),
            longestStreak: overallMetrics.currentStreak,
            topSongs: getTopSongs(),
            topArtists: getTopArtists()
        )
    }
    
    private func generateMonthlyStats(for monthStart: Date) -> MonthlyStats {
        // This would query Core Data for the month's sessions
        return MonthlyStats(
            monthStart: monthStart,
            totalSessions: overallMetrics.totalSessions,
            totalPlayTime: overallMetrics.totalPlayTime,
            uniqueSongsCount: sessionTracks.count,
            averageSessionDuration: overallMetrics.totalPlayTime / TimeInterval(max(overallMetrics.totalSessions, 1)),
            topGenres: getTopGenres(),
            topSongs: getTopSongs(),
            topArtists: getTopArtists()
        )
    }
    
    private func getTopSongs() -> [TopItem] {
        // Aggregate song data from session tracks
        let songCounts = Dictionary(grouping: sessionTracks) { $0.trackInfo.id }
            .mapValues { tracks in
                TopItem(
                    id: tracks.first?.trackInfo.id ?? "",
                    name: tracks.first?.trackInfo.title ?? "Unknown",
                    playCount: tracks.count,
                    totalTime: tracks.reduce(0) { $0 + $1.listeningTime }
                )
            }
        
        return Array(songCounts.values)
            .sorted { $0.playCount > $1.playCount }
            .prefix(10)
            .map { $0 }
    }
    
    private func getTopArtists() -> [TopItem] {
        // Aggregate artist data from session tracks
        let artistCounts = Dictionary(grouping: sessionTracks) { $0.trackInfo.artist ?? "Unknown" }
            .mapValues { tracks in
                TopItem(
                    id: tracks.first?.trackInfo.artist ?? "Unknown",
                    name: tracks.first?.trackInfo.artist ?? "Unknown",
                    playCount: tracks.count,
                    totalTime: tracks.reduce(0) { $0 + $1.listeningTime }
                )
            }
        
        return Array(artistCounts.values)
            .sorted { $0.playCount > $1.playCount }
            .prefix(10)
            .map { $0 }
    }
    
    private func getTopGenres() -> [TopItem] {
        // This would require genre information from tracks
        return []
    }
    
    // MARK: - Data Cleanup
    
    func cleanupOldData() {
        lastCleanupTime = Date()
        
        // This would typically clean up old Core Data records
        // For now, just limit in-memory session tracks
        if sessionTracks.count > 1000 {
            sessionTracks = Array(sessionTracks.suffix(500))
        }
    }
    
    // MARK: - Timer Management
    
    private func setupMetricsTimer() {
        metricsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateMetricsFromTimer()
        }
    }
    
    private func startMetricsTimer() {
        guard metricsTimer == nil else { return }
        setupMetricsTimer()
    }
    
    private func stopMetricsTimer() {
        metricsTimer?.invalidate()
        metricsTimer = nil
    }
    
    private func updateMetricsFromTimer() {
        guard isActive && !isPaused else { return }
        
        updateSessionDuration()
        updateSessionListeningTime()
    }
    
    // MARK: - Computed Properties
    
    var shouldProcessStats: Bool {
        guard let lastProcess = lastStatsProcessTime else { return true }
        return Date().timeIntervalSince(lastProcess) >= statsProcessingInterval
    }
    
    var shouldCleanupOldData: Bool {
        guard let lastCleanup = lastCleanupTime else { return true }
        return Date().timeIntervalSince(lastCleanup) >= dataCleanupInterval
    }
    
    var isValidSession: Bool {
        return sessionDuration >= minValidPlaybackTime && sessionMetrics.totalTracks > 0
    }
    
    // MARK: - Session Data Export
    
    func finalizeSession(duration: TimeInterval) -> SessionData {
        finalizeCurrentTrack()
        
        let tracks = sessionTracks.map { playback in
            TrackData(
                id: playback.trackInfo.id,
                title: playback.trackInfo.title,
                artist: playback.trackInfo.artist,
                album: playback.trackInfo.album,
                duration: playback.trackInfo.duration,
                playbackTime: playback.listeningTime,
                wasSkipped: playback.wasSkipped,
                timestamp: playback.startTime ?? Date()
            )
        }
        
        return SessionData(
            id: currentSessionID,
            startTime: sessionStartTime ?? Date(),
            endTime: Date(),
            duration: duration,
            songCount: sessionTracks.count,
            playCount: sessionMetrics.completedTracks,
            skipCount: sessionMetrics.skippedTracks,
            totalListeningTime: sessionMetrics.totalListeningTime,
            tracks: tracks
        )
    }
}

// MARK: - Data Structures

class TrackPlayback: ObservableObject {
    let trackInfo: TrackInfo
    var startTime: Date?
    var endTime: Date?
    var lastUpdateTime: Date?
    var lastKnownPosition: TimeInterval = 0
    var listeningTime: TimeInterval = 0
    var totalPlayTime: TimeInterval = 0
    var actualDuration: TimeInterval = 0
    var wasSkipped = false
    var isComplete = false
    
    init(trackInfo: TrackInfo, startTime: Date) {
        self.trackInfo = trackInfo
        self.startTime = startTime
        self.lastUpdateTime = startTime
    }
}

struct TrackInfo {
    let id: String
    let title: String?
    let artist: String?
    let album: String?
    let duration: TimeInterval
    let isExplicit: Bool
    let genres: [String]
    let artworkURL: String?
    
    init(from item: MPMediaItem) {
        self.id = item.persistentID.description
        self.title = item.title
        self.artist = item.artist
        self.album = item.albumTitle
        self.duration = item.playbackDuration
        self.isExplicit = item.isExplicitItem
        self.genres = [] // MPMediaItem doesn't provide genre access
        self.artworkURL = nil // Would need to process artwork separately
    }
}

struct SessionMetrics {
    var totalTracks = 0
    var currentTrackCount = 0
    var completedTracks = 0
    var skippedTracks = 0
    var totalListeningTime: TimeInterval = 0
    var uniqueArtists = Set<String>()
    var uniqueAlbums = Set<String>()
    
    mutating func reset() {
        totalTracks = 0
        currentTrackCount = 0
        completedTracks = 0
        skippedTracks = 0
        totalListeningTime = 0
        uniqueArtists.removeAll()
        uniqueAlbums.removeAll()
    }
}

struct OverallMetrics {
    var totalSessions = 0
    var totalPlayTime: TimeInterval = 0
    var currentSessionDuration: TimeInterval = 0
    var currentSessionListeningTime: TimeInterval = 0
    var currentStreak = 0
    var longestStreak = 0
    var lastActiveDate = Date()
    var lastSessionDate: Date?
    var weeklyStats: WeeklyStats?
    var monthlyStats: MonthlyStats?
    
    mutating func updateWithSession(_ sessionMetrics: SessionMetrics) {
        // Update overall statistics with completed session
    }
}

struct WeeklyStats {
    let weekStartDate: Date
    let totalSessions: Int
    let totalPlayTime: TimeInterval
    let uniqueSongsCount: Int
    let averageSessionDuration: TimeInterval
    let mostActiveDay: String
    let longestStreak: Int
    let topSongs: [TopItem]
    let topArtists: [TopItem]
}

struct MonthlyStats {
    let monthStart: Date
    let totalSessions: Int
    let totalPlayTime: TimeInterval
    let uniqueSongsCount: Int
    let averageSessionDuration: TimeInterval
    let topGenres: [TopItem]
    let topSongs: [TopItem]
    let topArtists: [TopItem]
}

struct TopItem {
    let id: String
    let name: String
    let playCount: Int
    let totalTime: TimeInterval
}