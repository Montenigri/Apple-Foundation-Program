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
    
    /// Genera suggerimenti solo per oggi, domani e dopodomani, solo fuori da sonno e lavoro, solo se non ci sono task/suggerimenti.
    func recalculateSuggestionsForNextThreeDays() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days: [Date] = (0...2).map { calendar.date(byAdding: .day, value: $0, to: today)! }
        
        // Rimuovi tutti i suggerimenti esistenti nei 3 giorni
        tasks.removeAll { task in
            task.isSuggested && days.contains(where: { calendar.isDate($0, inSameDayAs: task.startTime) })
        }
        
        for day in days {
            let dayTasks = tasks.filter { calendar.isDate($0.startTime, inSameDayAs: day) && !$0.isSuggested }
            let daySuggestions = tasks.filter { calendar.isDate($0.startTime, inSameDayAs: day) && $0.isSuggested }
            if !dayTasks.isEmpty { continue } // Se ci sono task, non suggerire
            if !daySuggestions.isEmpty { continue } // Se ci sono già suggerimenti, non suggerire

            // Calcola slot disponibili fuori da sonno e lavoro
            let sleepStart = profile.sleepStart
            let sleepEnd = profile.sleepEnd
            let workStart = profile.workStart
            let workEnd = profile.workEnd

            // Costruisci finestre di tempo disponibili
            let dayStart = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: day)!
            let dayEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: day)!

            // Slot: [dalle 00:00 a sleepEnd], [sleepEnd a workStart], [workEnd a sleepStart], [sleepStart a 23:59]
            var slots: [(start: Date, end: Date)] = []
            // 1. Prima del sonno
            if sleepEnd > dayStart {
                slots.append((dayStart, sleepEnd))
            }
            // 2. Dopo il sonno, prima del lavoro
            if workStart > sleepEnd {
                slots.append((sleepEnd, workStart))
            }
            // 3. Dopo il lavoro, prima del sonno
            if sleepStart > workEnd {
                slots.append((workEnd, sleepStart))
            }
            // 4. Dopo il sonno serale
            if dayEnd > sleepStart {
                slots.append((sleepStart, dayEnd))
            }

            // Per ogni slot, suggerisci interessi in base a preferenza e timeSlot
            var suggestions: [Task] = []
            for slot in slots {
                let availableTime = slot.end.timeIntervalSince(slot.start)
                if availableTime < 900 { continue }
                var currentTime = slot.start
                var remainingTime = availableTime
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
        }
        saveData()
    }
    
    /// Quando aggiungi un task, rimuovi eventuali suggerimenti sovrapposti e ricalcola per il giorno
    func addTask(_ task: Task) {
        // Rimuovi suggerimenti che si sovrappongono allo slot del nuovo task
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
    
    /// Ricalcola suggerimenti solo per un giorno specifico
    func recalculateSuggestionsForDay(_ date: Date) {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: day)!
        // Rimuovi suggerimenti di quel giorno
        tasks.removeAll { $0.isSuggested && $0.startTime >= day && $0.startTime < nextDay }
        // ...puoi riusare la logica di recalculateSuggestionsForNextThreeDays ma solo per quel giorno...
        // (per brevità, puoi estrarre la logica in una funzione privata se vuoi pulizia)
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

        // Definisci il range in base al tipo richiesto
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

        // 1. Prima del primo task
        if let first = sortedTasks.first, first.startTime > suggestionRange.start {
            timeSlots.append((suggestionRange.start, first.startTime))
        }

        // 2. Tra i task esistenti
        if sortedTasks.count > 1 {
            for i in 0..<sortedTasks.count - 1 {
                let currentEnd = sortedTasks[i].endTime
                let nextStart = sortedTasks[i + 1].startTime
                if nextStart.timeIntervalSince(currentEnd) > 900 {
                    // Solo se lo slot è nel range
                    if currentEnd >= suggestionRange.start && nextStart <= suggestionRange.end {
                        timeSlots.append((currentEnd, nextStart))
                    }
                }
            }
        }

        // 3. Dopo l’ultimo task
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

            // Filtra interessi per timeSlot e preferenza
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
    
    /// Rimuove un task e aggiorna i suggerimenti per il giorno
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
