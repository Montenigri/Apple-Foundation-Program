class TaskManager: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var interests: [Interest] = []
    @Published var profile = UserProfile()
    
    init() {
        loadData()
        requestNotificationPermission()
    }
    
    func addTask(_ task: Task) {
        tasks.append(task)
        scheduleNotifications(for: task)
        recalculateSuggestions()
        saveData()
    }
    
    func removeTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        recalculateSuggestions()
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
    
    private func recalculateSuggestions() {
        tasks.removeAll { $0.isSuggested }

        let calendar = Calendar.current
        let today = Date()
        let dayStart = calendar.startOfDay(for: today)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        let sortedTasks = tasks
            .filter { !$0.isSuggested }
            .sorted { $0.startTime < $1.startTime }

        var timeSlots: [(start: Date, end: Date)] = []

        // 1. Prima del primo task
        if let first = sortedTasks.first, first.startTime > dayStart {
            timeSlots.append((dayStart, first.startTime))
        }

        // 2. Tra i task esistenti
   
        if sortedTasks.count > 1 {
            for i in 0..<sortedTasks.count - 1 {
                let currentEnd = sortedTasks[i].endTime
                let nextStart = sortedTasks[i + 1].startTime
                if nextStart.timeIntervalSince(currentEnd) > 900 {
                    timeSlots.append((currentEnd, nextStart))
                }
            }
        }


        

        // 3. Dopo l’ultimo task
        if let last = sortedTasks.last, last.endTime < dayEnd {
            timeSlots.append((last.endTime, dayEnd))
        } else if sortedTasks.isEmpty {
            timeSlots.append((dayStart, dayEnd))
        }

        var suggestions: [Task] = []

        for slot in timeSlots {
            let availableTime = slot.end.timeIntervalSince(slot.start)
            if availableTime < 900 { continue }

            var currentTime = slot.start
            var remainingTime = availableTime

            let interestsByPreference = interests.sorted { $0.preferenceLevel > $1.preferenceLevel }

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
}
