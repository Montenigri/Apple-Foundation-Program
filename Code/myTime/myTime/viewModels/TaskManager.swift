import Foundation
import UserNotifications
import SwiftUI

class TaskManager: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var interests: [Interest] = []
    @Published var profile = UserProfile()
    
    init() {
        loadData()
        requestNotificationPermission()
    }
    
    /// Generates suggestions for today, tomorrow, and the day after tomorrow, only if there are no user tasks on that day
    func recalculateSuggestionsForNextThreeDays() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days: [Date] = (0...2).map { calendar.date(byAdding: .day, value: $0, to: today)! }
        // Remove all existing suggestions for the 3 days
        tasks.removeAll { task in
            task.isSuggested && days.contains(where: { calendar.isDate($0, inSameDayAs: task.startTime) })
        }
        for day in days {
            recalculateSuggestionsForDay(day)
        }
    }
    
    /// When adding a task, remove any overlapping suggestions and recalculate for the day
    func addTask(_ task: Task) {
        // Remove suggestions that overlap with the new task's time slot
        let calendar = Calendar.current
        tasks.removeAll { t in
            t.isSuggested && calendar.isDate(t.startTime, inSameDayAs: task.startTime) && (
                (t.startTime < task.endTime && t.endTime > task.startTime)
            )
        }
        tasks.append(task)
        scheduleNotifications(for: task)
        // Ricalcola solo per il giorno
        recalculateSuggestionsForDay(task.startTime)
        saveData()
    }
    
    /// Recalculate suggestions only for a specific day
    func recalculateSuggestionsForDay(_ date: Date) {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
        // Remove suggestions for that day
        tasks.removeAll { $0.isSuggested && $0.startTime >= day && $0.startTime < nextDay }
        // Find all user tasks for the day (exclude suggested ones)
        let dayTasks = tasks.filter { calendar.isDate($0.startTime, inSameDayAs: day) && !$0.isSuggested }
        // Calculate available slots between end of sleep and start of sleep, excluding work and user tasks
        let sleepStart = calendar.date(bySettingHour: calendar.component(.hour, from: profile.sleepStart), minute: calendar.component(.minute, from: profile.sleepStart), second: 0, of: day)!
        let sleepEnd = calendar.date(bySettingHour: calendar.component(.hour, from: profile.sleepEnd), minute: calendar.component(.minute, from: profile.sleepEnd), second: 0, of: day)!
        let workStart = calendar.date(bySettingHour: calendar.component(.hour, from: profile.workStart), minute: calendar.component(.minute, from: profile.workStart), second: 0, of: day)!
        let workEnd = calendar.date(bySettingHour: calendar.component(.hour, from: profile.workEnd), minute: calendar.component(.minute, from: profile.workEnd), second: 0, of: day)!
        // Build occupied blocks: sleep, work, user tasks
        var busyBlocks: [(start: Date, end: Date)] = []
        // Sleep: from sleepStart to sleepEnd (handle overnight cases)
        if sleepEnd > sleepStart {
            busyBlocks.append((sleepStart, sleepEnd))
        } else {
            // Sleep crosses midnight
            busyBlocks.append((sleepStart, calendar.date(byAdding: .day, value: 1, to: sleepEnd)!))
        }
        // Work
        if workEnd > workStart {
            busyBlocks.append((workStart, workEnd))
        }
        // Suer Task
        for t in dayTasks {
            busyBlocks.append((t.startTime, t.endTime))
        }
        // Sort the occupied blocks
        busyBlocks.sort { $0.start < $1.start }
        // Find free slots between the occupied blocks
        var freeSlots: [(start: Date, end: Date)] = []
        var cursor = day
        for block in busyBlocks {
            if block.start > cursor, block.start.timeIntervalSince(cursor) >= 900 {
                freeSlots.append((cursor, block.start))
            }
            cursor = max(cursor, block.end)
        }
        // Last slot until the end of the day
        if nextDay > cursor, nextDay.timeIntervalSince(cursor) >= 900 {
            freeSlots.append((cursor, nextDay))
        }
        // For each free slot, suggest interests based on preference and timeSlot
        var suggestions: [Task] = []
        for slot in freeSlots {
            let availableTime = slot.end.timeIntervalSince(slot.start)
            if availableTime < 900 { continue }
            var currentTime = slot.start
            var remainingTime = availableTime
            let interestsByPreference = interests
                .filter { interest in
                    let hour = calendar.component(.hour, from: currentTime)
                    switch interest.timeSlot.lowercased() {
                    case "morning":
                        return hour >= 6 && hour < 12
                    case "afternoon":
                        return hour >= 12 && hour < 18
                    case "evening":
                        return hour >= 18 && hour < 23
                    case "any":
                        return true
                    default:
                        return true
                    }
                }
                .sorted { $0.preferenceLevel > $1.preferenceLevel }
            for interest in interestsByPreference {
                if interest.duration <= remainingTime {
                    let newTask = Task(
                        name: interest.name,
                        description: "Suggerimento basato sui tuoi interessi",
                        duration: interest.duration,
                        location: "",
                        startTime: currentTime,
                        isSuggested: true
                    )
                    suggestions.append(newTask)
                    currentTime = currentTime.addingTimeInterval(interest.duration)
                    remainingTime -= interest.duration
                }
            }
        }
        tasks.append(contentsOf: suggestions)
        saveData()
    }
    
    func completeTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted = true
            profile.completedTasks += 1
            profile.totalHours += task.duration / 3600
            saveData()
        }
    }
    
    func addInterest(_ interest: Interest) {
        interests.append(interest)
        recalculateSuggestions()
        saveData()
    }
    
    func removeInterest(_ interest: Interest) {
        interests.removeAll { $0.id == interest.id }
        recalculateSuggestions()
        saveData()
    }
    
    
    //MARK: Recaculcalate suggestions
    
    private func recalculateSuggestions(rangeType: SuggestionRangeType = .today) {
        tasks.removeAll { $0.isSuggested }

        let calendar = Calendar.current
        let today = Date()
        let dayStart = calendar.startOfDay(for: today)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!

        // Define the range based on the requested type
        let suggestionRange: (start: Date, end: Date)
        switch rangeType {
        case .today:
            suggestionRange = (dayStart, dayEnd)
        case .week:
            suggestionRange = (weekStart, weekEnd)
        case .custom(let start, let end):
            suggestionRange = (start, end)
        }

        let sortedTasks = tasks
            .filter { !$0.isSuggested }
            .sorted { $0.startTime < $1.startTime }

        var timeSlots: [(start: Date, end: Date)] = []

        // 1. Before the first task
        if let first = sortedTasks.first, first.startTime > suggestionRange.start {
            timeSlots.append((suggestionRange.start, first.startTime))
        }

        // 2. Between existing tasks
        if sortedTasks.count > 1 {
            for i in 0..<sortedTasks.count - 1 {
                let currentEnd = sortedTasks[i].endTime
                let nextStart = sortedTasks[i + 1].startTime
                if nextStart.timeIntervalSince(currentEnd) > 900 {
                    // Only if the slot is within the range
                    if currentEnd >= suggestionRange.start && nextStart <= suggestionRange.end {
                        timeSlots.append((currentEnd, nextStart))
                    }
                }
            }
        }

        // 3. After the last task
        if let last = sortedTasks.last, last.endTime < suggestionRange.end {
            timeSlots.append((last.endTime, suggestionRange.end))
        } else if sortedTasks.isEmpty {
            timeSlots.append((suggestionRange.start, suggestionRange.end))
        }

        var suggestions: [Task] = []

        for slot in timeSlots {
            let availableTime = slot.end.timeIntervalSince(slot.start)
            if availableTime < 900 { continue }

            var currentTime = slot.start
            var remainingTime = availableTime

            // Filter interests by timeSlot and preference
            let interestsByPreference = interests
                .filter { interest in
                    // timeSlot: "morning", "afternoon", "evening", "any"
                    let hour = calendar.component(.hour, from: currentTime)
                    switch interest.timeSlot.lowercased() {
                    case "morning":
                        return hour >= 6 && hour < 12
                    case "afternoon":
                        return hour >= 12 && hour < 18
                    case "evening":
                        return hour >= 18 && hour < 23
                    case "any":
                        return true
                    default:
                        return true
                    }
                }
                .sorted { $0.preferenceLevel > $1.preferenceLevel }

            for interest in interestsByPreference {
                if interest.duration <= remainingTime {
                    let newTask = Task(
                        name: interest.name,
                        description: "Suggerimento basato sui tuoi interessi",
                        duration: interest.duration,
                        location: "",
                        startTime: currentTime,
                        isSuggested: true
                    )
                    suggestions.append(newTask)
                    currentTime = currentTime.addingTimeInterval(interest.duration)
                    remainingTime -= interest.duration
                }
            }
        }

        tasks.append(contentsOf: suggestions)
        saveData()
    }
    
    private func findBestInterests(for availableTime: TimeInterval) -> [Interest] {
        let sortedInterests = interests.sorted { $0.preferenceLevel > $1.preferenceLevel }
        var selectedInterests: [Interest] = []
        var remainingTime = availableTime
        
        for interest in sortedInterests {
            if interest.duration <= remainingTime {
                selectedInterests.append(interest)
                remainingTime -= interest.duration
            }
        }
        
        return selectedInterests
    }
    
    private func scheduleNotifications(for task: Task) {
        let center = UNUserNotificationCenter.current()
        
        // 5 minutes before
        let beforeContent = UNMutableNotificationContent()
        beforeContent.title = "MyTime"
        beforeContent.body = "Il task '\(task.name)' inizierà tra 5 minuti"
        beforeContent.sound = .default
        
        let beforeTrigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(task.startTime.timeIntervalSinceNow - 300, 1),
            repeats: false
        )
        
        let beforeRequest = UNNotificationRequest(
            identifier: "\(task.id.uuidString)-before",
            content: beforeContent,
            trigger: beforeTrigger
        )
        
        // 10 minutes after
        let afterContent = UNMutableNotificationContent()
        afterContent.title = "MyTime"
        afterContent.body = "Hai completato il task '\(task.name)'?"
        afterContent.sound = .default
        
        let afterTrigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(task.endTime.timeIntervalSinceNow + 600, 1),
            repeats: false
        )
        
        let afterRequest = UNNotificationRequest(
            identifier: "\(task.id.uuidString)-after",
            content: afterContent,
            trigger: afterTrigger
        )
        
        center.add(beforeRequest)
        center.add(afterRequest)
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }
    
    private func saveData() {
        if let tasksData = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(tasksData, forKey: "tasks")
        }
        if let interestsData = try? JSONEncoder().encode(interests) {
            UserDefaults.standard.set(interestsData, forKey: "interests")
        }
        if let profileData = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(profileData, forKey: "profile")
        }
    }
    
    private func loadData() {
        if let tasksData = UserDefaults.standard.data(forKey: "tasks"),
           let decodedTasks = try? JSONDecoder().decode([Task].self, from: tasksData) {
            tasks = decodedTasks
        }
        if let interestsData = UserDefaults.standard.data(forKey: "interests"),
           let decodedInterests = try? JSONDecoder().decode([Interest].self, from: interestsData) {
            interests = decodedInterests
        }
        if let profileData = UserDefaults.standard.data(forKey: "profile"),
           let decodedProfile = try? JSONDecoder().decode(UserProfile.self, from: profileData) {
            profile = decodedProfile
        }
    }
    func toggleTaskCompletion(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            let wasCompleted = tasks[index].isCompleted
            tasks[index].isCompleted.toggle()

            var updatedProfile = profile

            if tasks[index].isCompleted && !wasCompleted {
                updatedProfile.completedTasks += 1
            } else if !tasks[index].isCompleted && wasCompleted {
                updatedProfile.completedTasks = max(updatedProfile.completedTasks - 1, 0)
            }

            profile = updatedProfile // Riassegno per triggerare @Published

            saveData()
        }
    }



    func getTasksForDate(_ date: Date) -> [Task] {
        let calendar = Calendar.current
        return tasks.filter { calendar.isDate($0.startTime, inSameDayAs: date) }
    }
    
    /// Removes a task and updates suggestions for the day
    func removeTask(_ task: Task) {
        let calendar = Calendar.current
        tasks.removeAll { $0.id == task.id }
        recalculateSuggestionsForDay(task.startTime)
        saveData()
    }
}

enum SuggestionRangeType {
    case today
    case week
    case custom(start: Date, end: Date)
}
