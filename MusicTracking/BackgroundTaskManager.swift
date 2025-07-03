import Foundation
import BackgroundTasks
import os.log

class BackgroundTaskManager: ObservableObject {
    static let shared = BackgroundTaskManager()
    
    private let logger = Logger(subsystem: "jaba.MusicTracking", category: "BackgroundTask")
    
    enum TaskIdentifier: String, CaseIterable {
        case cleanup = "jaba.MusicTracking.cleanup"
        case stats = "jaba.MusicTracking.stats"
        case monitoring = "jaba.MusicTracking.monitoring"
    }
    
    enum TaskError: Error {
        case registrationFailed
        case schedulingFailed
        case executionFailed(String)
        case expiredBeforeCompletion
    }
    
    struct TaskHistory {
        let identifier: String
        let scheduledAt: Date
        let executedAt: Date?
        let completedAt: Date?
        let error: String?
        let duration: TimeInterval?
        let result: String?
    }
    
    @Published private(set) var taskHistory: [TaskHistory] = []
    @Published private(set) var isRegistered = false
    @Published private(set) var lastScheduleResults: [String: Bool] = [:]
    
    private var activeTaskRequests: [String: BGTaskRequest] = [:]
    private let historyLimit = 100
    
    private init() {
        loadTaskHistory()
    }
    
    func registerBackgroundTasks() {
        logger.info("Registering background tasks")
        
        var allRegistered = true
        
        for taskId in TaskIdentifier.allCases {
            let success = BGTaskScheduler.shared.register(
                forTaskWithIdentifier: taskId.rawValue,
                using: nil
            ) { task in
                self.handleBackgroundTask(task, identifier: taskId)
            }
            
            if success {
                logger.info("Successfully registered task: \(taskId.rawValue)")
            } else {
                logger.error("Failed to register task: \(taskId.rawValue)")
                allRegistered = false
            }
        }
        
        DispatchQueue.main.async {
            self.isRegistered = allRegistered
        }
    }
    
    func scheduleAllTasks() {
        logger.info("Scheduling all background tasks")
        
        for taskId in TaskIdentifier.allCases {
            scheduleTask(taskId)
        }
    }
    
    func scheduleTask(_ taskIdentifier: TaskIdentifier) {
        logger.info("Scheduling task: \(taskIdentifier.rawValue)")
        
        let request: BGTaskRequest
        
        switch taskIdentifier {
        case .cleanup:
            request = createCleanupTaskRequest()
        case .stats:
            request = createStatsTaskRequest()
        case .monitoring:
            request = createMonitoringTaskRequest()
        }
        
        do {
            try BGTaskScheduler.shared.submit(request)
            activeTaskRequests[taskIdentifier.rawValue] = request
            logger.info("Successfully scheduled task: \(taskIdentifier.rawValue)")
            
            recordTaskScheduled(taskIdentifier.rawValue)
            
            DispatchQueue.main.async {
                self.lastScheduleResults[taskIdentifier.rawValue] = true
            }
        } catch {
            logger.error("Failed to schedule task \(taskIdentifier.rawValue): \(error.localizedDescription)")
            
            DispatchQueue.main.async {
                self.lastScheduleResults[taskIdentifier.rawValue] = false
            }
        }
    }
    
    private func createCleanupTaskRequest() -> BGProcessingTaskRequest {
        let request = BGProcessingTaskRequest(identifier: TaskIdentifier.cleanup.rawValue)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60) // 1 hour from now
        return request
    }
    
    private func createStatsTaskRequest() -> BGProcessingTaskRequest {
        let request = BGProcessingTaskRequest(identifier: TaskIdentifier.stats.rawValue)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60) // 30 minutes from now
        return request
    }
    
    private func createMonitoringTaskRequest() -> BGAppRefreshTaskRequest {
        let request = BGAppRefreshTaskRequest(identifier: TaskIdentifier.monitoring.rawValue)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now
        return request
    }
    
    private func handleBackgroundTask(_ task: BGTask, identifier: TaskIdentifier) {
        logger.info("Handling background task: \(identifier.rawValue)")
        
        let startTime = Date()
        recordTaskExecuted(identifier.rawValue, at: startTime)
        
        task.expirationHandler = {
            self.logger.warning("Task \(identifier.rawValue) expired before completion")
            self.recordTaskCompleted(identifier.rawValue, startTime: startTime, 
                                   error: "Task expired before completion", result: nil)
            task.setTaskCompleted(success: false)
        }
        
        Task {
            do {
                let result = try await executeTask(identifier)
                let duration = Date().timeIntervalSince(startTime)
                
                logger.info("Task \(identifier.rawValue) completed successfully in \(duration)s")
                recordTaskCompleted(identifier.rawValue, startTime: startTime, 
                                  error: nil, result: result)
                
                task.setTaskCompleted(success: true)
                
                scheduleTask(identifier)
                
            } catch {
                let duration = Date().timeIntervalSince(startTime)
                logger.error("Task \(identifier.rawValue) failed after \(duration)s: \(error.localizedDescription)")
                
                recordTaskCompleted(identifier.rawValue, startTime: startTime, 
                                  error: error.localizedDescription, result: nil)
                
                task.setTaskCompleted(success: false)
                
                scheduleTask(identifier)
            }
        }
    }
    
    private func executeTask(_ identifier: TaskIdentifier) async throws -> String {
        switch identifier {
        case .cleanup:
            return try await executeCleanupTask()
        case .stats:
            return try await executeStatsTask()
        case .monitoring:
            return try await executeMonitoringTask()
        }
    }
    
    private func executeCleanupTask() async throws -> String {
        logger.info("Executing cleanup task")
        
        let context = PersistenceController.shared.container.newBackgroundContext()
        var itemsDeleted = 0
        
        return try await context.perform {
            let request = Item.fetchRequest()
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            request.predicate = NSPredicate(format: "timestamp < %@", cutoffDate as NSDate)
            
            do {
                let oldItems = try context.fetch(request)
                itemsDeleted = oldItems.count
                
                for item in oldItems {
                    context.delete(item)
                }
                
                if context.hasChanges {
                    try context.save()
                }
                
                return "Deleted \(itemsDeleted) old items"
            } catch {
                throw TaskError.executionFailed("Cleanup failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func executeStatsTask() async throws -> String {
        logger.info("Executing stats task")
        
        let context = PersistenceController.shared.container.newBackgroundContext()
        
        return try await context.perform {
            let request = Item.fetchRequest()
            request.predicate = NSPredicate(format: "timestamp >= %@", 
                                          Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date() as NSDate)
            
            do {
                let recentItems = try context.fetch(request)
                let stats = [
                    "total_items": recentItems.count,
                    "avg_per_day": recentItems.count / 7
                ]
                
                UserDefaults.standard.set(stats, forKey: "weekly_stats")
                
                return "Generated stats for \(recentItems.count) items"
            } catch {
                throw TaskError.executionFailed("Stats generation failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func executeMonitoringTask() async throws -> String {
        logger.info("Executing monitoring task")
        
        let startTime = Date()
        
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second simulation
        
        let systemInfo = [
            "memory_pressure": ProcessInfo.processInfo.isLowPowerModeEnabled ? "high" : "normal",
            "battery_level": "unknown",
            "last_check": ISO8601DateFormatter().string(from: startTime)
        ]
        
        UserDefaults.standard.set(systemInfo, forKey: "system_monitoring")
        
        return "System monitoring completed"
    }
    
    private func recordTaskScheduled(_ identifier: String) {
        let history = TaskHistory(
            identifier: identifier,
            scheduledAt: Date(),
            executedAt: nil,
            completedAt: nil,
            error: nil,
            duration: nil,
            result: nil
        )
        
        DispatchQueue.main.async {
            self.taskHistory.insert(history, at: 0)
            self.trimHistory()
            self.saveTaskHistory()
        }
    }
    
    private func recordTaskExecuted(_ identifier: String, at date: Date) {
        DispatchQueue.main.async {
            if let index = self.taskHistory.firstIndex(where: { 
                $0.identifier == identifier && $0.executedAt == nil 
            }) {
                var history = self.taskHistory[index]
                history = TaskHistory(
                    identifier: history.identifier,
                    scheduledAt: history.scheduledAt,
                    executedAt: date,
                    completedAt: history.completedAt,
                    error: history.error,
                    duration: history.duration,
                    result: history.result
                )
                self.taskHistory[index] = history
                self.saveTaskHistory()
            }
        }
    }
    
    private func recordTaskCompleted(_ identifier: String, startTime: Date, error: String?, result: String?) {
        let completedAt = Date()
        let duration = completedAt.timeIntervalSince(startTime)
        
        DispatchQueue.main.async {
            if let index = self.taskHistory.firstIndex(where: { 
                $0.identifier == identifier && $0.completedAt == nil 
            }) {
                var history = self.taskHistory[index]
                history = TaskHistory(
                    identifier: history.identifier,
                    scheduledAt: history.scheduledAt,
                    executedAt: history.executedAt,
                    completedAt: completedAt,
                    error: error,
                    duration: duration,
                    result: result
                )
                self.taskHistory[index] = history
                self.saveTaskHistory()
            }
        }
    }
    
    private func trimHistory() {
        if taskHistory.count > historyLimit {
            taskHistory.removeLast(taskHistory.count - historyLimit)
        }
    }
    
    private func saveTaskHistory() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(taskHistory)
            UserDefaults.standard.set(data, forKey: "background_task_history")
        } catch {
            logger.error("Failed to save task history: \(error.localizedDescription)")
        }
    }
    
    private func loadTaskHistory() {
        guard let data = UserDefaults.standard.data(forKey: "background_task_history") else {
            return
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            taskHistory = try decoder.decode([TaskHistory].self, from: data)
        } catch {
            logger.error("Failed to load task history: \(error.localizedDescription)")
            taskHistory = []
        }
    }
    
    func getTaskHistoryForIdentifier(_ identifier: String) -> [TaskHistory] {
        return taskHistory.filter { $0.identifier == identifier }
    }
    
    func getTaskDiagnostics() -> [String: Any] {
        let successfulTasks = taskHistory.filter { $0.error == nil && $0.completedAt != nil }
        let failedTasks = taskHistory.filter { $0.error != nil }
        let averageDuration = successfulTasks.compactMap { $0.duration }.reduce(0, +) / Double(max(successfulTasks.count, 1))
        
        return [
            "total_tasks": taskHistory.count,
            "successful_tasks": successfulTasks.count,
            "failed_tasks": failedTasks.count,
            "average_duration": averageDuration,
            "success_rate": Double(successfulTasks.count) / Double(max(taskHistory.count, 1)) * 100,
            "is_registered": isRegistered,
            "last_schedule_results": lastScheduleResults,
            "active_requests": activeTaskRequests.keys.sorted()
        ]
    }
    
    func clearHistory() {
        taskHistory.removeAll()
        saveTaskHistory()
    }
}

extension BackgroundTaskManager.TaskHistory: Codable {}