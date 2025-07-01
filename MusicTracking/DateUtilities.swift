import Foundation

struct DateUtilities {
    static let shared = DateUtilities()
    private init() {}
    
    private let calendar = Calendar.current
    
    // MARK: - Date Formatters
    
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
    
    static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    // MARK: - Week Calculations
    
    func startOfWeek(for date: Date = Date()) -> Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }
    
    func endOfWeek(for date: Date = Date()) -> Date {
        let startOfWeek = startOfWeek(for: date)
        return calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? date
    }
    
    func datesInCurrentWeek(from date: Date = Date()) -> [Date] {
        let startOfWeek = startOfWeek(for: date)
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    func weekOfYear(for date: Date = Date()) -> Int {
        return calendar.component(.weekOfYear, from: date)
    }
    
    func isSameWeek(_ date1: Date, _ date2: Date) -> Bool {
        return startOfWeek(for: date1) == startOfWeek(for: date2)
    }
    
    func weeksAgo(_ weeks: Int, from date: Date = Date()) -> Date {
        return calendar.date(byAdding: .weekOfYear, value: -weeks, to: date) ?? date
    }
    
    func weeksBetween(_ startDate: Date, _ endDate: Date) -> Int {
        let components = calendar.dateComponents([.weekOfYear], from: startDate, to: endDate)
        return components.weekOfYear ?? 0
    }
    
    // MARK: - Day Calculations
    
    func startOfDay(for date: Date = Date()) -> Date {
        return calendar.startOfDay(for: date)
    }
    
    func endOfDay(for date: Date = Date()) -> Date {
        let startOfDay = startOfDay(for: date)
        return calendar.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(-1) ?? date
    }
    
    func isToday(_ date: Date) -> Bool {
        return calendar.isDateInToday(date)
    }
    
    func isYesterday(_ date: Date) -> Bool {
        return calendar.isDateInYesterday(date)
    }
    
    func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        return calendar.isDate(date1, inSameDayAs: date2)
    }
    
    func daysBetween(_ startDate: Date, _ endDate: Date) -> Int {
        let components = calendar.dateComponents([.day], from: startOfDay(for: startDate), to: startOfDay(for: endDate))
        return components.day ?? 0
    }
    
    func daysAgo(_ days: Int, from date: Date = Date()) -> Date {
        return calendar.date(byAdding: .day, value: -days, to: date) ?? date
    }
    
    // MARK: - Time Intervals
    
    func timeInterval(from startDate: Date, to endDate: Date) -> TimeInterval {
        return endDate.timeIntervalSince(startDate)
    }
    
    func minutesBetween(_ startDate: Date, _ endDate: Date) -> Int {
        let interval = timeInterval(from: startDate, to: endDate)
        return Int(interval / 60)
    }
    
    func hoursBetween(_ startDate: Date, _ endDate: Date) -> Double {
        let interval = timeInterval(from: startDate, to: endDate)
        return interval / 3600
    }
    
    // MARK: - Relative Date Formatting
    
    func relativeString(for date: Date, from referenceDate: Date = Date()) -> String {
        if isToday(date) {
            return "Today"
        } else if isYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: referenceDate, toGranularity: .weekOfYear) {
            return DateUtilities.weekdayFormatter.string(from: date)
        } else {
            let daysDiff = daysBetween(date, referenceDate)
            if daysDiff < 7 && daysDiff > 0 {
                return "\(daysDiff) day\(daysDiff == 1 ? "" : "s") ago"
            } else if daysDiff < 30 {
                let weeks = daysDiff / 7
                return "\(weeks) week\(weeks == 1 ? "" : "s") ago"
            } else {
                return DateUtilities.shortDateFormatter.string(from: date)
            }
        }
    }
    
    // MARK: - Duration Formatting
    
    func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let remainingSeconds = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        } else {
            return String(format: "%d:%02d", minutes, remainingSeconds)
        }
    }
    
    func formatDurationShort(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(Int(seconds))s"
        }
    }
    
    func formatDurationLong(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        var components: [String] = []
        
        if hours > 0 {
            components.append("\(hours) hour\(hours == 1 ? "" : "s")")
        }
        
        if minutes > 0 {
            components.append("\(minutes) minute\(minutes == 1 ? "" : "s")")
        }
        
        if components.isEmpty {
            return "Less than a minute"
        }
        
        return components.joined(separator: ", ")
    }
    
    // MARK: - Date Range Queries
    
    func dateRange(for period: TimePeriod, from referenceDate: Date = Date()) -> DateInterval {
        let startDate: Date
        let endDate: Date
        
        switch period {
        case .today:
            startDate = startOfDay(for: referenceDate)
            endDate = endOfDay(for: referenceDate)
            
        case .yesterday:
            let yesterday = daysAgo(1, from: referenceDate)
            startDate = startOfDay(for: yesterday)
            endDate = endOfDay(for: yesterday)
            
        case .thisWeek:
            startDate = startOfWeek(for: referenceDate)
            endDate = endOfWeek(for: referenceDate)
            
        case .lastWeek:
            let lastWeek = weeksAgo(1, from: referenceDate)
            startDate = startOfWeek(for: lastWeek)
            endDate = endOfWeek(for: lastWeek)
            
        case .thisMonth:
            let components = calendar.dateComponents([.year, .month], from: referenceDate)
            startDate = calendar.date(from: components) ?? referenceDate
            endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate) ?? referenceDate
            
        case .lastMonth:
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: referenceDate) ?? referenceDate
            let components = calendar.dateComponents([.year, .month], from: lastMonth)
            startDate = calendar.date(from: components) ?? referenceDate
            endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate) ?? referenceDate
            
        case .last7Days:
            startDate = startOfDay(for: daysAgo(6, from: referenceDate))
            endDate = endOfDay(for: referenceDate)
            
        case .last30Days:
            startDate = startOfDay(for: daysAgo(29, from: referenceDate))
            endDate = endOfDay(for: referenceDate)
            
        case .last90Days:
            startDate = startOfDay(for: daysAgo(89, from: referenceDate))
            endDate = endOfDay(for: referenceDate)
            
        case .thisYear:
            let components = calendar.dateComponents([.year], from: referenceDate)
            startDate = calendar.date(from: components) ?? referenceDate
            endDate = calendar.date(byAdding: DateComponents(year: 1, day: -1), to: startDate) ?? referenceDate
        }
        
        return DateInterval(start: startDate, end: endDate)
    }
}

// MARK: - Calendar Extensions

extension Calendar {
    func numberOfDaysInMonth(for date: Date) -> Int {
        return range(of: .day, in: .month, for: date)?.count ?? 0
    }
    
    func firstDayOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
    
    func lastDayOfMonth(for date: Date) -> Date {
        let firstDay = firstDayOfMonth(for: date)
        return self.date(byAdding: DateComponents(month: 1, day: -1), to: firstDay) ?? date
    }
    
    func isWeekend(_ date: Date) -> Bool {
        let weekday = component(.weekday, from: date)
        return weekday == 1 || weekday == 7 // Sunday = 1, Saturday = 7
    }
    
    func nextWeekday(_ weekday: Int, after date: Date) -> Date? {
        let currentWeekday = component(.weekday, from: date)
        let daysToAdd = (weekday - currentWeekday + 7) % 7
        let targetDays = daysToAdd == 0 ? 7 : daysToAdd
        return self.date(byAdding: .day, value: targetDays, to: date)
    }
}

// MARK: - Date Extensions

extension Date {
    var startOfWeek: Date {
        return DateUtilities.shared.startOfWeek(for: self)
    }
    
    var endOfWeek: Date {
        return DateUtilities.shared.endOfWeek(for: self)
    }
    
    var startOfDay: Date {
        return DateUtilities.shared.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        return DateUtilities.shared.endOfDay(for: self)
    }
    
    var isToday: Bool {
        return DateUtilities.shared.isToday(self)
    }
    
    var isYesterday: Bool {
        return DateUtilities.shared.isYesterday(self)
    }
    
    func isSameWeek(as date: Date) -> Bool {
        return DateUtilities.shared.isSameWeek(self, date)
    }
    
    func isSameDay(as date: Date) -> Bool {
        return DateUtilities.shared.isSameDay(self, date)
    }
    
    func relativeString(from referenceDate: Date = Date()) -> String {
        return DateUtilities.shared.relativeString(for: self, from: referenceDate)
    }
}

// MARK: - Time Period Enum

enum TimePeriod: String, CaseIterable {
    case today = "Today"
    case yesterday = "Yesterday"
    case thisWeek = "This Week"
    case lastWeek = "Last Week"
    case thisMonth = "This Month"
    case lastMonth = "Last Month"
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"
    case last90Days = "Last 90 Days"
    case thisYear = "This Year"
    
    var displayName: String {
        return rawValue
    }
}