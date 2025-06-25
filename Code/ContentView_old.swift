import SwiftUI
import UserNotifications

// MARK: - Color Palette
extension Color {
    static let appBlack = Color(hex: "#0f1416")
    static let appDarkBlue = Color(hex: "#2b4466")
    static let appLightBlue = Color(hex: "#78a4df")
    static let appBeige = Color(hex: "#eee8dc")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Data Models
struct Task: Identifiable, Codable {
    let id = UUID()
    var name: String
    var description: String
    var duration: TimeInterval
    var location: String
    var startTime: Date
    var isCompleted: Bool = false
    var isSuggested: Bool = false
    var endTime: Date {
        return startTime.addingTimeInterval(duration)
    }
}

struct Interest: Identifiable, Codable {
    let id = UUID()
    var name: String
    var duration: TimeInterval
    var preferenceLevel: Int // 1-5 scale
    var timeSlot: String
}

struct UserProfile: Codable {
    var nickname: String = ""
    var completedTasks: Int = 0
    var totalHours: Double = 0
    var sleepStart: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    var sleepEnd: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    var workStart: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    var workEnd: Date = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
}

// MARK: - Task Manager
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

// MARK: - Main App View
struct ContentView_old: View {
    @StateObject private var taskManager = TaskManager()
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            Color.appBlack.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Slider
                CustomSlider(selectedTab: $selectedTab)
                    .padding(.top, 20)
                
                // Content
                TabView(selection: $selectedTab) {
                    MyTimeView()
                        .tag(0)
                        .environmentObject(taskManager)
                    
                    AddTaskView()
                        .tag(1)
                        .environmentObject(taskManager)
                    
                    ProfileView()
                        .tag(2)
                        .environmentObject(taskManager)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
    }
}

// MARK: - Custom Slider
struct CustomSlider: View {
    @Binding var selectedTab: Int
    let tabs = ["MyTime", "Add Task", "Profile"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = index
                    }
                }) {
                    Text(tabs[index])
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedTab == index ? .appBeige : .appBeige.opacity(0.4))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedTab == index ? Color.appDarkBlue : Color.clear)
                        )
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.appDarkBlue.opacity(0.3))
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - MyTime View
struct MyTimeView: View {
    @EnvironmentObject var taskManager: TaskManager
    @State private var selectedTask: Task?
    
    var body: some View {
        ZStack {
            Color.appBlack.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // Fixed Header
                VStack(alignment: .leading, spacing: 5) {
                    Text(currentMonth())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.appBeige)
                    
                    HStack {
                        Text(currentWeekday())
                            .font(.headline)
                            .foregroundColor(.appBeige)
                        
                        Text(currentDay())
                            .font(.headline)
                            .foregroundColor(.appBeige)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Tasks ScrollView
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(sortedTasks()) { task in
                            TaskRowView(task: task) {
                                selectedTask = task
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task){
                selectedTask = nil
            }
                .environmentObject(taskManager)
        }
    }
    
    private func sortedTasks() -> [Task] {
        return taskManager.tasks.sorted { $0.startTime < $1.startTime }
    }
    
    private func currentMonth() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: Date())
    }
    
    private func currentWeekday() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: Date())
    }
    
    private func currentDay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: Date())
    }
}

// MARK: - Task Row View
struct TaskRowView: View {
    let task: Task
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Priority bar
                Rectangle()
                    .fill(task.isSuggested ? Color.appLightBlue : Color.appDarkBlue)
                    .frame(width: 4)
                    .cornerRadius(2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.name)
                        .font(.headline)
                        .foregroundColor(.appDarkBlue)
                        .multilineTextAlignment(.leading)
                    
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.caption)
                            .foregroundColor(.appDarkBlue.opacity(0.7))
                            .multilineTextAlignment(.leading)
                    }
                    
                    HStack {
                        Text(timeString(from: task.startTime))
                            .font(.caption)
                            .foregroundColor(.appDarkBlue.opacity(0.7))
                        
                        if !task.location.isEmpty {
                            Text("• \(task.location)")
                                .font(.caption)
                                .foregroundColor(.appDarkBlue.opacity(0.7))
                        }
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(task.isCompleted ? Color.appBeige.opacity(0.3) : Color.appBeige)
            )
            .opacity(task.isCompleted ? 0.5 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Task Detail View
struct TaskDetailView: View {
    let task: Task
    let onDelete: () -> Void
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(task.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.appBeige)
                        
                        if !task.description.isEmpty {
                            Text(task.description)
                                .font(.body)
                                .foregroundColor(.appBeige.opacity(0.8))
                        }
                        
                        HStack {
                            Text("Inizio: \(timeString(from: task.startTime))")
                                .font(.subheadline)
                                .foregroundColor(.appLightBlue)
                            
                            Spacer()
                            
                            Text("Fine: \(timeString(from: task.endTime))")
                                .font(.subheadline)
                                .foregroundColor(.appLightBlue)
                        }
                        
                        if !task.location.isEmpty {
                            Text("Luogo: \(task.location)")
                                .font(.subheadline)
                                .foregroundColor(.appBeige.opacity(0.8))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appDarkBlue.opacity(0.3))
                    )
                    
                    Spacer()
                }
                .padding()
            }
            .background(Color.appBlack)
            .navigationTitle("Dettagli Task")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Chiudi") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .alert("Conferma rimozione", isPresented: $showingDeleteAlert) {
            Button("Annulla", role: .cancel) { }
            Button("Rimuovi", role: .destructive) {
                taskManager.removeTask(task)
                onDelete() //notifico la view genitore
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Sei sicuro di voler rimuovere questo task?")
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Add Task View
struct AddTaskView: View {
    @EnvironmentObject var taskManager: TaskManager
    @State private var name = ""
    @State private var description = ""
    @State private var duration = Date()
    @State private var location = ""
    @State private var startTime = Date()
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            Color.appBlack.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Nuovo Task")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.appBeige)
                        
                        // Name field
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Nome attività")
                                .font(.subheadline)
                                .foregroundColor(.appBeige)
                            
                            TextField("Inserisci nome", text: $name)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Description field
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Descrizione")
                                .font(.subheadline)
                                .foregroundColor(.appBeige)
                            
                            TextField("Inserisci descrizione", text: $description, axis: .vertical)
                                .textFieldStyle(CustomTextFieldStyle())
                                .lineLimit(3...6)
                        }
                        
                        // Start time
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Orario di inizio")
                                .font(.subheadline)
                                .foregroundColor(.appBeige)
                            
                            DatePicker("", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(CompactDatePickerStyle())
                                .colorScheme(.dark)
                        }
                        
                        // Duration
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Durata")
                                .font(.subheadline)
                                .foregroundColor(.appBeige)
                            
                            DatePicker("", selection: $duration, displayedComponents: .hourAndMinute)
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                                .frame(height: 100)
                        }
                        
                        // Location field
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Luogo")
                                .font(.subheadline)
                                .foregroundColor(.appBeige)
                            
                            TextField("Inserisci luogo", text: $location)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Add button
                        Button("Aggiungi Task") {
                            addTask()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.appDarkBlue)
                        )
                        .foregroundColor(.appBeige)
                        .disabled(name.isEmpty)
                        .opacity(name.isEmpty ? 0.5 : 1.0)
                    }
                    .padding()
                }
            }
        }
        .alert("Attenzione", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func addTask() {
        let calendar = Calendar.current
        let durationComponents = calendar.dateComponents([.hour, .minute], from: duration)
        let durationInSeconds = TimeInterval((durationComponents.hour ?? 0) * 3600 + (durationComponents.minute ?? 0) * 60)
        
        let newTask = Task(
            name: name,
            description: description,
            duration: durationInSeconds,
            location: location,
            startTime: startTime
        )
        
        let endTime = startTime.addingTimeInterval(durationInSeconds)
        
        // Verifica conflitti con altri task reali
        let hasConflict = taskManager.tasks.contains { existingTask in
            !existingTask.isSuggested && (startTime < existingTask.endTime && endTime > existingTask.startTime)
        }
        
        if hasConflict {
            alertMessage = "Esiste già un task in questo slot temporale"
            showingAlert = true
        } else {
            // Rimuovi eventuali task suggeriti sovrapposti
            taskManager.tasks.removeAll {
                $0.isSuggested && (startTime < $0.endTime && endTime > $0.startTime)
            }
            
            taskManager.addTask(newTask)
            
            // Reset form
            name = ""
            description = ""
            duration = Date()
            location = ""
            startTime = Date()
            
            alertMessage = "Task aggiunto con successo!"
            showingAlert = true
        }
    }

}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.appBeige)
            )
            .foregroundColor(.appDarkBlue)
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var taskManager: TaskManager
    @State private var showingInterests = false
    
    var body: some View {
        ZStack {
            Color.appBlack.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 15) {
                        Text("Progressi")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.appBeige)
                        
                       
                    }
                    
                    // Progress section
                    VStack(spacing: 15) {
                        Text("I tuoi progressi")
                            .font(.headline)
                            .foregroundColor(.appBeige)
                        
                        HStack {
                            VStack {
                                Text("\(taskManager.profile.completedTasks)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.appLightBlue)
                                Text("Task completati")
                                    .font(.caption)
                                    .foregroundColor(.appBeige)
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text(String(format: "%.1f", taskManager.profile.totalHours))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.appLightBlue)
                                Text("Ore totali")
                                    .font(.caption)
                                    .foregroundColor(.appBeige)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.appDarkBlue.opacity(0.3))
                        )
                    }
                    
                    // Sleep section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Sezione Sonno")
                            .font(.headline)
                            .foregroundColor(.appBeige)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Inizio")
                                    .font(.caption)
                                    .foregroundColor(.appBeige)
                                DatePicker("", selection: $taskManager.profile.sleepStart, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text("Fine")
                                    .font(.caption)
                                    .foregroundColor(.appBeige)
                                DatePicker("", selection: $taskManager.profile.sleepEnd, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appDarkBlue.opacity(0.3))
                    )
                    
                    // Work section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Sezione Lavoro")
                            .font(.headline)
                            .foregroundColor(.appBeige)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Inizio")
                                    .font(.caption)
                                    .foregroundColor(.appBeige)
                                DatePicker("", selection: $taskManager.profile.workStart, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text("Fine")
                                    .font(.caption)
                                    .foregroundColor(.appBeige)
                                DatePicker("", selection: $taskManager.profile.workEnd, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appDarkBlue.opacity(0.3))
                    )
                    
                    // Interests button
                    Button("Seleziona Interessi") {
                        showingInterests = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appDarkBlue)
                    )
                    .foregroundColor(.appBeige)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingInterests) {
            InterestsView()
                .environmentObject(taskManager)
        }
    }
}


// MARK: - Interests View
struct InterestsView: View {
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAddInterest = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBlack.ignoresSafeArea()
                
                VStack {
                    if taskManager.interests.isEmpty {
                        Text("Nessun interesse aggiunto")
                            .foregroundColor(.appBeige)
                            .padding()
                    } else {
                        ScrollView {
                            ForEach(taskManager.interests) { interest in
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(interest.name)
                                        .font(.headline)
                                        .foregroundColor(.appLightBlue)
                                    Text("Durata: \(Int(interest.duration / 60)) min | Preferenza: \(interest.preferenceLevel) | Fascia: \(interest.timeSlot)")
                                        .font(.subheadline)
                                        .foregroundColor(.appBeige)
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.appDarkBlue.opacity(0.3)))
                                .swipeActions {
                                    Button(role: .destructive) {
                                        taskManager.removeInterest(interest)
                                    } label: {
                                        Label("Rimuovi", systemImage: "trash")
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                    
                    Button("Aggiungi interessi") {
                        showingAddInterest = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.appDarkBlue))
                    .foregroundColor(.appBeige)
                    .padding()
                }
            }
            .navigationTitle("Seleziona Interessi")
            .sheet(isPresented: $showingAddInterest) {
                AddInterestView()
                    .environmentObject(taskManager)
            }
        }
    }
}

// MARK: - Add Interest View
struct AddInterestView: View {
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.presentationMode) var presentationMode

    @State private var name: String = ""
    @State private var durationMinutes: Int = 30
    @State private var preferenceLevel: Int = 3
    @State private var selectedTimeSlot: String = "Mattina"  // valore di default

    let timeSlots = ["Mattina", "Pomeriggio", "Sera"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Nome interesse").foregroundColor(.appBeige)) {
                    TextField("Es. Lettura, Meditazione", text: $name)
                }

                Section(header: Text("Durata (minuti)").foregroundColor(.appBeige)) {
                    Stepper("\(durationMinutes) minuti", value: $durationMinutes, in: 5...180, step: 5)
                }

                Section(header: Text("Grado di preferenza").foregroundColor(.appBeige)) {
                    Picker("Preferenza", selection: $preferenceLevel) {
                        ForEach(1...5, id: \.self) { level in
                            Text("⭐️ \(level)").tag(level)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Fascia oraria").foregroundColor(.appBeige)) {
                    Picker("Fascia oraria", selection: $selectedTimeSlot) {
                        ForEach(timeSlots, id: \.self) { slot in
                            Text(slot)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section {
                    Button("Salva interesse") {
                        let interest = Interest(
                            name: name,
                            duration: TimeInterval(durationMinutes * 60),
                            preferenceLevel: preferenceLevel,
                            timeSlot: selectedTimeSlot
                        )
                        taskManager.addInterest(interest)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(name.isEmpty)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.appBeige)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.appDarkBlue))
                }
            }
            .foregroundColor(.black)
            .background(Color.appBlack.ignoresSafeArea())
            .scrollContentBackground(.hidden)
            .navigationTitle("Aggiungi Interesse")
        }
    }

}
