import Foundation
import MusicKit

enum AppError: LocalizedError, Equatable {
    
    // MARK: - MusicKit Errors
    case musicKitUnauthorized
    case musicKitNotSupported
    case musicKitNetworkUnavailable
    case musicKitRequestFailed(String)
    case musicKitDataCorrupted
    case musicKitRateLimited
    case musicKitSubscriptionRequired
    
    // MARK: - Core Data Errors
    case coreDataSaveFailed(String)
    case coreDataFetchFailed(String)
    case coreDataMigrationFailed(String)
    case coreDataContextUnavailable
    case coreDataValidationFailed(String)
    case cloudKitSyncFailed(String)
    case cloudKitAccountUnavailable
    
    // MARK: - Background Task Errors
    case backgroundTaskRegistrationFailed
    case backgroundTaskExecutionFailed(String)
    case backgroundTaskTimeout
    case backgroundTaskPermissionDenied
    
    // MARK: - Data Processing Errors
    case dataParsingFailed(String)
    case dataCorrupted(String)
    case dataValidationFailed(String)
    case dataExportFailed(String)
    
    // MARK: - Network Errors
    case networkUnavailable
    case networkTimeout
    case serverError(Int)
    case invalidResponse
    
    // MARK: - General Errors
    case unknownError(String)
    case configurationError(String)
    case featureUnavailable(String)
    
    var errorDescription: String? {
        switch self {
        // MARK: - MusicKit Error Descriptions
        case .musicKitUnauthorized:
            return "Music access is required to track your listening habits."
        case .musicKitNotSupported:
            return "Music tracking is not supported on this device."
        case .musicKitNetworkUnavailable:
            return "Unable to connect to Apple Music. Check your internet connection."
        case .musicKitRequestFailed(let message):
            return "Music request failed: \(message)"
        case .musicKitDataCorrupted:
            return "Music data appears to be corrupted. Please try again."
        case .musicKitRateLimited:
            return "Too many music requests. Please wait a moment and try again."
        case .musicKitSubscriptionRequired:
            return "An active Apple Music subscription is required for full functionality."
            
        // MARK: - Core Data Error Descriptions
        case .coreDataSaveFailed(let message):
            return "Failed to save your data: \(message)"
        case .coreDataFetchFailed(let message):
            return "Failed to load your data: \(message)"
        case .coreDataMigrationFailed(let message):
            return "Failed to update your data format: \(message)"
        case .coreDataContextUnavailable:
            return "Data storage is temporarily unavailable."
        case .coreDataValidationFailed(let message):
            return "Data validation failed: \(message)"
        case .cloudKitSyncFailed(let message):
            return "Failed to sync with iCloud: \(message)"
        case .cloudKitAccountUnavailable:
            return "iCloud account is not available. Please sign in to iCloud in Settings."
            
        // MARK: - Background Task Error Descriptions
        case .backgroundTaskRegistrationFailed:
            return "Failed to register background monitoring. Music tracking may be limited."
        case .backgroundTaskExecutionFailed(let message):
            return "Background task failed: \(message)"
        case .backgroundTaskTimeout:
            return "Background task timed out. Some data may not be captured."
        case .backgroundTaskPermissionDenied:
            return "Background app refresh is disabled. Enable it in Settings for complete tracking."
            
        // MARK: - Data Processing Error Descriptions
        case .dataParsingFailed(let message):
            return "Failed to process data: \(message)"
        case .dataCorrupted(let message):
            return "Data corruption detected: \(message)"
        case .dataValidationFailed(let message):
            return "Invalid data: \(message)"
        case .dataExportFailed(let message):
            return "Failed to export data: \(message)"
            
        // MARK: - Network Error Descriptions
        case .networkUnavailable:
            return "No internet connection available."
        case .networkTimeout:
            return "Network request timed out. Please try again."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .invalidResponse:
            return "Received invalid response from server."
            
        // MARK: - General Error Descriptions
        case .unknownError(let message):
            return "An unexpected error occurred: \(message)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .featureUnavailable(let message):
            return "Feature unavailable: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        // MARK: - MusicKit Recovery Suggestions
        case .musicKitUnauthorized:
            return "Go to Settings > Privacy & Security > Media & Apple Music to grant access."
        case .musicKitNotSupported:
            return "This feature requires iOS 15.0 or later with Apple Music support."
        case .musicKitNetworkUnavailable:
            return "Check your internet connection and try again."
        case .musicKitRequestFailed:
            return "Please try again in a few moments."
        case .musicKitDataCorrupted:
            return "Restart the app and try again."
        case .musicKitRateLimited:
            return "Wait a few minutes before making more requests."
        case .musicKitSubscriptionRequired:
            return "Subscribe to Apple Music for full tracking capabilities."
            
        // MARK: - Core Data Recovery Suggestions
        case .coreDataSaveFailed, .coreDataFetchFailed:
            return "Restart the app and try again. If the problem persists, contact support."
        case .coreDataMigrationFailed:
            return "Update the app to the latest version and restart."
        case .coreDataContextUnavailable:
            return "Wait a moment and try again."
        case .coreDataValidationFailed:
            return "Check your data and try again."
        case .cloudKitSyncFailed:
            return "Check your iCloud connection and try again."
        case .cloudKitAccountUnavailable:
            return "Sign in to iCloud in Settings > [Your Name] > iCloud."
            
        // MARK: - Background Task Recovery Suggestions
        case .backgroundTaskRegistrationFailed:
            return "Restart the app to re-register background tasks."
        case .backgroundTaskExecutionFailed:
            return "Check app permissions and background app refresh settings."
        case .backgroundTaskTimeout:
            return "This is normal and doesn't affect your data."
        case .backgroundTaskPermissionDenied:
            return "Go to Settings > General > Background App Refresh and enable it for Music Tracking."
            
        // MARK: - Data Processing Recovery Suggestions
        case .dataParsingFailed, .dataCorrupted, .dataValidationFailed:
            return "Try refreshing your data or restart the app."
        case .dataExportFailed:
            return "Check your device storage and try again."
            
        // MARK: - Network Recovery Suggestions
        case .networkUnavailable:
            return "Connect to Wi-Fi or cellular data and try again."
        case .networkTimeout:
            return "Check your internet connection speed and try again."
        case .serverError:
            return "The service is temporarily unavailable. Please try again later."
        case .invalidResponse:
            return "Try again or contact support if the problem persists."
            
        // MARK: - General Recovery Suggestions
        case .unknownError:
            return "Restart the app and try again. Contact support if the problem persists."
        case .configurationError:
            return "Update the app to the latest version."
        case .featureUnavailable:
            return "This feature may not be available on your device or iOS version."
        }
    }
    
    var failureReason: String? {
        switch self {
        case .musicKitUnauthorized:
            return "The app doesn't have permission to access your music library."
        case .musicKitNotSupported:
            return "MusicKit is not available on this device."
        case .musicKitNetworkUnavailable:
            return "Network connection is required for Apple Music integration."
        case .musicKitRateLimited:
            return "Too many requests have been made to Apple Music."
        case .musicKitSubscriptionRequired:
            return "Apple Music subscription is required for this feature."
        case .coreDataContextUnavailable:
            return "The data storage system is not ready."
        case .cloudKitAccountUnavailable:
            return "No iCloud account is configured on this device."
        case .backgroundTaskPermissionDenied:
            return "Background app refresh is disabled for this app."
        case .networkUnavailable:
            return "No active internet connection."
        default:
            return nil
        }
    }
    
    var category: ErrorCategory {
        switch self {
        case .musicKitUnauthorized, .musicKitNotSupported, .musicKitNetworkUnavailable,
             .musicKitRequestFailed, .musicKitDataCorrupted, .musicKitRateLimited,
             .musicKitSubscriptionRequired:
            return .musicKit
            
        case .coreDataSaveFailed, .coreDataFetchFailed, .coreDataMigrationFailed,
             .coreDataContextUnavailable, .coreDataValidationFailed, .cloudKitSyncFailed,
             .cloudKitAccountUnavailable:
            return .dataStorage
            
        case .backgroundTaskRegistrationFailed, .backgroundTaskExecutionFailed,
             .backgroundTaskTimeout, .backgroundTaskPermissionDenied:
            return .backgroundProcessing
            
        case .dataParsingFailed, .dataCorrupted, .dataValidationFailed, .dataExportFailed:
            return .dataProcessing
            
        case .networkUnavailable, .networkTimeout, .serverError, .invalidResponse:
            return .network
            
        case .unknownError, .configurationError, .featureUnavailable:
            return .general
        }
    }
    
    var isRecoverable: Bool {
        switch self {
        case .musicKitUnauthorized, .musicKitNetworkUnavailable, .musicKitRateLimited,
             .cloudKitAccountUnavailable, .backgroundTaskPermissionDenied,
             .networkUnavailable, .networkTimeout:
            return true
        default:
            return false
        }
    }
    
    var shouldRetry: Bool {
        switch self {
        case .musicKitNetworkUnavailable, .musicKitRateLimited, .networkUnavailable,
             .networkTimeout, .serverError, .backgroundTaskTimeout:
            return true
        default:
            return false
        }
    }
}

enum ErrorCategory: String, CaseIterable {
    case musicKit = "MusicKit"
    case dataStorage = "Data Storage"
    case backgroundProcessing = "Background Processing"
    case dataProcessing = "Data Processing"
    case network = "Network"
    case general = "General"
}

extension AppError {
    static func from(musicKitError: MusicKitError) -> AppError {
        switch musicKitError {
        case .notAuthorized:
            return .musicKitUnauthorized
        case .notSupported:
            return .musicKitNotSupported
        case .networkUnavailable:
            return .musicKitNetworkUnavailable
        case .rateLimited:
            return .musicKitRateLimited
        default:
            return .musicKitRequestFailed(musicKitError.localizedDescription)
        }
    }
    
    static func from(coreDataError: Error) -> AppError {
        let nsError = coreDataError as NSError
        let description = nsError.localizedDescription
        
        switch nsError.code {
        case 134060, 134030:
            return .coreDataMigrationFailed(description)
        case 1560, 1570:
            return .coreDataValidationFailed(description)
        default:
            if nsError.domain == "NSCocoaErrorDomain" {
                return .coreDataSaveFailed(description)
            } else {
                return .coreDataFetchFailed(description)
            }
        }
    }
}