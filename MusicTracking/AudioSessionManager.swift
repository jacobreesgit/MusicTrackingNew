import Foundation
import AVFoundation
import MediaPlayer

class AudioSessionManager: ObservableObject {
    static let shared = AudioSessionManager()
    
    // MARK: - Properties
    @Published private(set) var isConfigured = false
    @Published private(set) var currentCategory: AVAudioSession.Category = .playback
    @Published private(set) var currentMode: AVAudioSession.Mode = .default
    @Published private(set) var isActive = false
    
    private let audioSession = AVAudioSession.sharedInstance()
    private var hasConfiguredSession = false
    
    // MARK: - Audio Session Categories and Options
    private let foregroundCategory: AVAudioSession.Category = .playback
    private let backgroundCategory: AVAudioSession.Category = .playback
    
    private let foregroundOptions: AVAudioSession.CategoryOptions = [
        .mixWithOthers,
        .allowAirPlay,
        .allowBluetooth,
        .allowBluetoothA2DP
    ]
    
    private let backgroundOptions: AVAudioSession.CategoryOptions = [
        .mixWithOthers,
        .allowAirPlay,
        .allowBluetooth,
        .allowBluetoothA2DP,
        .duckOthers
    ]
    
    private init() {
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    func configure() throws {
        do {
            try configureForForegroundMonitoring()
            hasConfiguredSession = true
            isConfigured = true
        } catch {
            isConfigured = false
            throw AppError.configurationError("Failed to configure audio session: \(error.localizedDescription)")
        }
    }
    
    func configureForForegroundMonitoring() {
        do {
            try audioSession.setCategory(
                foregroundCategory,
                mode: .default,
                options: foregroundOptions
            )
            
            try audioSession.setActive(true, options: [])
            
            currentCategory = foregroundCategory
            currentMode = .default
            isActive = true
            
            // Configure remote control events
            configureRemoteControlEvents()
            
        } catch {
            NotificationHelper.postError(
                AppError.configurationError("Failed to configure foreground audio session: \(error.localizedDescription)"),
                source: "AudioSessionManager"
            )
        }
    }
    
    func configureForBackgroundMonitoring() {
        do {
            try audioSession.setCategory(
                backgroundCategory,
                mode: .default,
                options: backgroundOptions
            )
            
            // Don't activate session in background - let the system manage it
            currentCategory = backgroundCategory
            currentMode = .default
            
        } catch {
            NotificationHelper.postError(
                AppError.configurationError("Failed to configure background audio session: \(error.localizedDescription)"),
                source: "AudioSessionManager"
            )
        }
    }
    
    func deactivate() {
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
            isActive = false
            
            // Disable remote control events
            disableRemoteControlEvents()
            
        } catch {
            NotificationHelper.postError(
                AppError.configurationError("Failed to deactivate audio session: \(error.localizedDescription)"),
                source: "AudioSessionManager"
            )
        }
    }
    
    func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            handleInterruptionBegan(userInfo)
            
        case .ended:
            handleInterruptionEnded(userInfo)
            
        @unknown default:
            break
        }
    }
    
    func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .newDeviceAvailable:
            handleNewDeviceAvailable(userInfo)
            
        case .oldDeviceUnavailable:
            handleOldDeviceUnavailable(userInfo)
            
        case .categoryChange:
            handleCategoryChange(userInfo)
            
        case .override:
            handleRouteOverride(userInfo)
            
        case .wakeFromSleep:
            handleWakeFromSleep(userInfo)
            
        case .noSuitableRouteForCategory:
            handleNoSuitableRoute(userInfo)
            
        case .routeConfigurationChange:
            handleRouteConfigurationChange(userInfo)
            
        @unknown default:
            break
        }
    }
    
    // MARK: - Remote Control Configuration
    
    private func configureRemoteControlEvents() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // We don't want to interfere with actual music playback controls
        // Just observe the events for tracking purposes
        
        commandCenter.playCommand.isEnabled = false
        commandCenter.pauseCommand.isEnabled = false
        commandCenter.stopCommand.isEnabled = false
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        
        // But we can still observe these events
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.handleRemotePlay()
            return .noSuchContent
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.handleRemotePause()
            return .noSuchContent
        }
        
        commandCenter.stopCommand.addTarget { [weak self] _ in
            self?.handleRemoteStop()
            return .noSuchContent
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.handleRemoteNextTrack()
            return .noSuchContent
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.handleRemotePreviousTrack()
            return .noSuchContent
        }
    }
    
    private func disableRemoteControlEvents() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.removeTarget(self)
        commandCenter.pauseCommand.removeTarget(self)
        commandCenter.stopCommand.removeTarget(self)
        commandCenter.nextTrackCommand.removeTarget(self)
        commandCenter.previousTrackCommand.removeTarget(self)
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: audioSession
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: audioSession
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMediaServicesReset),
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: audioSession
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMediaServicesLost),
            name: AVAudioSession.mediaServicesWereLostNotification,
            object: audioSession
        )
    }
    
    private func handleInterruptionBegan(_ userInfo: [AnyHashable: Any]) {
        isActive = false
        
        // Check if interruption was due to another app
        if let wasSuspended = userInfo[AVAudioSessionInterruptionWasSuspendedKey] as? Bool,
           wasSuspended {
            // App was suspended - normal behavior
        }
        
        NotificationHelper.post(
            name: .musicTrackingPaused,
            userInfo: [NotificationKeys.reason: "Audio session interrupted"]
        )
    }
    
    private func handleInterruptionEnded(_ userInfo: [AnyHashable: Any]) {
        guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
            return
        }
        
        let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
        
        if options.contains(.shouldResume) {
            do {
                try audioSession.setActive(true)
                isActive = true
                
                NotificationHelper.post(
                    name: .musicTrackingResumed,
                    userInfo: [NotificationKeys.reason: "Audio session interruption ended"]
                )
            } catch {
                NotificationHelper.postError(
                    AppError.configurationError("Failed to reactivate audio session: \(error.localizedDescription)"),
                    source: "AudioSessionManager"
                )
            }
        }
    }
    
    private func handleNewDeviceAvailable(_ userInfo: [AnyHashable: Any]) {
        // New audio device connected (headphones, speakers, etc.)
        let currentRoute = audioSession.currentRoute
        
        var deviceInfo: [String: Any] = [:]
        
        for output in currentRoute.outputs {
            deviceInfo["outputType"] = output.portType.rawValue
            deviceInfo["outputName"] = output.portName
        }
        
        NotificationHelper.post(
            name: .settingsDidChange,
            userInfo: [
                NotificationKeys.settingKey: "audioRoute",
                NotificationKeys.newValue: deviceInfo,
                NotificationKeys.reason: "New audio device connected"
            ]
        )
    }
    
    private func handleOldDeviceUnavailable(_ userInfo: [AnyHashable: Any]) {
        // Audio device disconnected (headphones unplugged, etc.)
        if let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
            
            var deviceInfo: [String: Any] = [:]
            
            for output in previousRoute.outputs {
                deviceInfo["outputType"] = output.portType.rawValue
                deviceInfo["outputName"] = output.portName
            }
            
            NotificationHelper.post(
                name: .settingsDidChange,
                userInfo: [
                    NotificationKeys.settingKey: "audioRoute",
                    NotificationKeys.oldValue: deviceInfo,
                    NotificationKeys.reason: "Audio device disconnected"
                ]
            )
        }
    }
    
    private func handleCategoryChange(_ userInfo: [AnyHashable: Any]) {
        currentCategory = audioSession.category
        currentMode = audioSession.mode
        
        NotificationHelper.post(
            name: .settingsDidChange,
            userInfo: [
                NotificationKeys.settingKey: "audioCategory",
                NotificationKeys.newValue: currentCategory.rawValue,
                NotificationKeys.reason: "Audio session category changed"
            ]
        )
    }
    
    private func handleRouteOverride(_ userInfo: [AnyHashable: Any]) {
        // Route was overridden (e.g., forced to speaker)
    }
    
    private func handleWakeFromSleep(_ userInfo: [AnyHashable: Any]) {
        // Device woke from sleep - may need to reconfigure session
        if hasConfiguredSession {
            configureForForegroundMonitoring()
        }
    }
    
    private func handleNoSuitableRoute(_ userInfo: [AnyHashable: Any]) {
        // No suitable audio route available
        NotificationHelper.postError(
            AppError.configurationError("No suitable audio route available"),
            source: "AudioSessionManager"
        )
    }
    
    private func handleRouteConfigurationChange(_ userInfo: [AnyHashable: Any]) {
        // Audio route configuration changed
    }
    
    // MARK: - Remote Control Handlers
    
    private func handleRemotePlay() {
        // User pressed play on remote control - we just observe this
    }
    
    private func handleRemotePause() {
        // User pressed pause on remote control - we just observe this
    }
    
    private func handleRemoteStop() {
        // User pressed stop on remote control - we just observe this
    }
    
    private func handleRemoteNextTrack() {
        // User pressed next track on remote control - we just observe this
    }
    
    private func handleRemotePreviousTrack() {
        // User pressed previous track on remote control - we just observe this
    }
    
    // MARK: - Notification Handlers
    
    @objc private func handleAudioSessionInterruption(_ notification: Notification) {
        handleInterruption(notification)
    }
    
    @objc private func handleAudioSessionRouteChange(_ notification: Notification) {
        handleRouteChange(notification)
    }
    
    @objc private func handleMediaServicesReset(_ notification: Notification) {
        // Media services were reset - need to reconfigure everything
        isConfigured = false
        hasConfiguredSession = false
        isActive = false
        
        NotificationHelper.postError(
            AppError.configurationError("Media services were reset"),
            source: "AudioSessionManager"
        )
        
        // Attempt to reconfigure
        do {
            try configure()
        } catch {
            NotificationHelper.postError(
                error as! AppError,
                source: "AudioSessionManager"
            )
        }
    }
    
    @objc private func handleMediaServicesLost(_ notification: Notification) {
        // Media services were lost - similar to reset but more severe
        isConfigured = false
        hasConfiguredSession = false
        isActive = false
        
        NotificationHelper.postError(
            AppError.configurationError("Media services were lost"),
            source: "AudioSessionManager"
        )
    }
    
    // MARK: - Audio Session Info
    
    var currentRouteDescription: String {
        let route = audioSession.currentRoute
        var description = "Inputs: "
        
        for input in route.inputs {
            description += "\(input.portName) (\(input.portType.rawValue)) "
        }
        
        description += "| Outputs: "
        
        for output in route.outputs {
            description += "\(output.portName) (\(output.portType.rawValue)) "
        }
        
        return description
    }
    
    var availableInputs: [AVAudioSessionPortDescription] {
        return audioSession.availableInputs ?? []
    }
    
    var isHeadphonesConnected: Bool {
        let route = audioSession.currentRoute
        return route.outputs.contains { output in
            output.portType == .headphones || 
            output.portType == .bluetoothA2DP ||
            output.portType == .bluetoothHFP ||
            output.portType == .bluetoothLE
        }
    }
    
    var isBluetoothConnected: Bool {
        let route = audioSession.currentRoute
        return route.outputs.contains { output in
            output.portType == .bluetoothA2DP ||
            output.portType == .bluetoothHFP ||
            output.portType == .bluetoothLE
        }
    }
    
    var isSpeakerActive: Bool {
        let route = audioSession.currentRoute
        return route.outputs.contains { output in
            output.portType == .builtInSpeaker
        }
    }
    
    var preferredSampleRate: Double {
        return audioSession.preferredSampleRate
    }
    
    var preferredIOBufferDuration: TimeInterval {
        return audioSession.preferredIOBufferDuration
    }
}