import SwiftUI
import UserNotifications
import EventKit


struct Task: Identifiable, Codable {
    var id = UUID()
    var name: String
    var description: String
    var date: Date
    var category: TaskCategory
    var isCompleted: Bool = false
    var duration: TimeInterval = 3600 // Default 1 hour
}

enum TaskCategory: String, CaseIterable, Codable {
    case general = "GENERAL"
    case bug = "BUG"
    case idea = "IDEA"
    case modifiers = "MODIFIERS"
    case challenge = "CHALLENGE"
    case coding = "CODING"
    
    var color: Color {
        switch self {
        case .general: return Color.gray
        case .bug: return Color.green
        case .idea: return Color.pink
        case .modifiers: return Color.blue
        case .challenge: return Color.purple
        case .coding: return Color.orange
        }
    }
}

// MARK: - Aggiornamento UserProgress per nickname e interessi
struct UserProgress: Codable {
    var totalTasksCompleted: Int = 0
    var streakDays: Int = 0
    var totalTimeSpent: TimeInterval = 0
    var lastActivityDate: Date?
    var nickname: String = ""
    var selectedInterests: [String] = []
}

// MARK: - Lista interessi predefiniti
let predefinedInterests = [
    "Programming", "Design", "Reading", "Exercise", "Cooking",
    "Music", "Photography", "Writing", "Learning", "Meditation",
    "Gaming", "Art", "Travel", "Business", "Health"
]


// MARK: - ViewModels
class TaskManager: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var userProgress = UserProgress()
    
    private let notificationManager = NotificationManager()
    
    init() {
        loadTasks()
        loadProgress()
        requestNotificationPermission()
    }
    
    func addTask(_ task: Task) {
        tasks.append(task)
        saveTasks()
        scheduleNotifications(for: task)
    }
    
    func completeTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted = true
            userProgress.totalTasksCompleted += 1
            userProgress.totalTimeSpent += task.duration
            updateStreak()
            saveTasks()
            saveProgress()
        }
    }
    
    func getTasksForDate(_ date: Date) -> [Task] {
        let calendar = Calendar.current
        return tasks.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    private func updateStreak() {
        let today = Date()
        if let lastDate = userProgress.lastActivityDate {
            let daysDifference = Calendar.current.dateComponents([.day], from: lastDate, to: today).day ?? 0
            if daysDifference == 1 {
                userProgress.streakDays += 1
            } else if daysDifference > 1 {
                userProgress.streakDays = 1
            }
        } else {
            userProgress.streakDays = 1
        }
        userProgress.lastActivityDate = today
    }
    
    private func scheduleNotifications(for task: Task) {
        notificationManager.scheduleTaskNotification(for: task)
    }
    
    private func requestNotificationPermission() {
        notificationManager.requestPermission()
    }
    
    // MARK: - Persistence
    private func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: "SavedTasks")
        }
    }
    
    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: "SavedTasks"),
           let decodedTasks = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = decodedTasks
        }
    }
    
    private func saveProgress() {
        if let data = try? JSONEncoder().encode(userProgress) {
            UserDefaults.standard.set(data, forKey: "UserProgress")
        }
    }
    
    private func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: "UserProgress"),
           let decodedProgress = try? JSONDecoder().decode(UserProgress.self, from: data) {
            userProgress = decodedProgress
        }
    }
}

// MARK: - Notification Manager
class NotificationManager: NSObject, ObservableObject {
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleTaskNotification(for task: Task) {
        let content = UNMutableNotificationContent()
        content.title = "Time for: \(task.name)"
        content.body = task.description.isEmpty ? "Your scheduled task is starting now!" : task.description
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: task.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: task.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
        
        // Schedule completion reminder (1 hour after start)
        let completionContent = UNMutableNotificationContent()
        completionContent.title = "Task Check-in"
        completionContent.body = "Did you complete: \(task.name)?"
        completionContent.sound = .default
        
        let completionDate = task.date.addingTimeInterval(task.duration)
        let completionComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: completionDate)
        let completionTrigger = UNCalendarNotificationTrigger(dateMatching: completionComponents, repeats: false)
        
        let completionRequest = UNNotificationRequest(
            identifier: "\(task.id.uuidString)_completion",
            content: completionContent,
            trigger: completionTrigger
        )
        
        UNUserNotificationCenter.current().add(completionRequest)
    }
}

// MARK: - Custom Colors
extension Color {
    static let appBlack = Color(hex: "#0f1416")
    static let appDarkBlue = Color(hex: "#2b4466")
    static let appLightBlue = Color(hex: "#78a4df")
    static let appBeige = Color(hex: "#eee8dc")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Main App View
struct ContentView: View {
    @StateObject private var taskManager = TaskManager()
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            Color.appBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom Slider Tab
                HStack {
                    TabButton(title: "MyTime", isSelected: selectedTab == 0) {
                        withAnimation {
                            selectedTab = 0
                        }
                    }
                    TabButton(title: "Add Task", isSelected: selectedTab == 1) {
                        withAnimation {
                            selectedTab = 1
                        }
                    }
                    TabButton(title: "Profile", isSelected: selectedTab == 2) {
                        withAnimation {
                            selectedTab = 2
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)

                // Page transition
                TabView(selection: $selectedTab) {
                    MyTimeView(taskManager: taskManager)
                        .tag(0)
                    AddTaskView(taskManager: taskManager)
                        .tag(1)
                    ProfileView(taskManager: taskManager)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: selectedTab)
            }
        }
    }
}


struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isSelected ? .appBeige : .appBeige.opacity(0.3))
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(isSelected ? Color.appDarkBlue : Color.clear)
                )
        }
    }
}



// MARK: - MyTimeView aggiornata con header fisso e layout migliorato
struct MyTimeView: View {
    @ObservedObject var taskManager: TaskManager
    @State private var selectedDate = Date()
    @State private var showDetail: Bool = false
    @State private var selectedTask: Task?
    
    let daysRange = 0..<30
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header fisso con mese corrente
                    VStack(alignment: .leading, spacing: 8) {
                        Text(DateFormatter.currentMonth.string(from: Date()))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.appDarkBlue)
                        
                        Rectangle()
                            .fill(Color.appLightBlue.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .background(Color.white)
                    
                    // Contenuto scrollabile
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            ForEach(daysRange, id: \.self) { offset in
                                let day = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
                                let tasks = taskManager.getTasksForDate(day)
                                
                                if !tasks.isEmpty {
                                    VStack(alignment: .leading, spacing: 0) {
                                        // Header giorno - layout a bandiera
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(DateFormatter.dayName.string(from: day))
                                                    .font(.caption)
                                                    .foregroundColor(.gray)
                                                Text("\(Calendar.current.component(.day, from: day))")
                                                    .font(.title2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.appDarkBlue)
                                            }
                                            .frame(width: 60, alignment: .leading)
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal)
                                        .padding(.bottom, 12)
                                        
                                        // Tasks del giorno
                                        ForEach(tasks.sorted(by: { $0.date < $1.date })) { task in
                                            Button {
                                                selectedTask = task
                                                showDetail = true
                                            } label: {
                                                CalendarTaskRow(task: task, isLast: task.id == tasks.last?.id)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, 16)
                    }
                }
                
            }
            .navigationDestination(isPresented: $showDetail) {
                if let task = selectedTask {
                    TaskDetailView(task: task, taskManager: taskManager)
                }
            }
        }
    }
}




// MARK: - TaskDetailView aggiornata con pulsanti completamento e rimozione
struct TaskDetailView: View {
    let task: Task
    @ObservedObject var taskManager: TaskManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Text(task.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.appDarkBlue)
                    .multilineTextAlignment(.center)
                
                Text(task.description)
                    .font(.body)
                    .foregroundColor(.appDarkBlue.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.appLightBlue)
                    Text("\(DateFormatter.fullDate.string(from: task.date)) at \(DateFormatter.time.string(from: task.date))")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundColor(task.category.color)
                    Text(task.category.rawValue)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.appBeige.opacity(0.3))
            )
            
            Spacer()
            
            // Pulsanti azione
            VStack(spacing: 12) {
                // Pulsante completamento
                Button(action: {
                    taskManager.toggleTaskCompletion(task.id)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        Text(task.isCompleted ? "Mark as Incomplete" : "Mark as Complete")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(task.isCompleted ? Color.orange : Color.green)
                    )
                }
                
                // Pulsante rimozione
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Task")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.red)
                    )
                }
            }
        }
        .padding()
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.white.ignoresSafeArea())
        .alert("Delete Task", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                taskManager.removeTask(task)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this task? This action cannot be undone.")
        }
    }
}











// MARK: - Week Calendar View
struct WeekCalendarView: View {
    @Binding var selectedDate: Date
    @ObservedObject var taskManager: TaskManager
    
    private let calendar = Calendar.current
    private let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    var body: some View {
        VStack {
            // Week Days
            HStack {
                ForEach(weekDays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.appLightBlue)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Week Dates
            HStack {
                ForEach(weekDates(), id: \.self) { date in
                    let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                    let hasTask = !taskManager.getTasksForDate(date).isEmpty
                    
                    Button(action: {
                        selectedDate = date
                    }) {
                        VStack {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                                .foregroundColor(isSelected ? .appBlack : .appBeige)
                                .frame(width: 35, height: 35)
                                .background(
                                    Circle()
                                        .fill(isSelected ? Color.appLightBlue : Color.clear)
                                )
                            
                            if hasTask {
                                Circle()
                                    .fill(Color.appLightBlue)
                                    .frame(width: 4, height: 4)
                            } else {
                                Spacer()
                                    .frame(height: 4)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    private func weekDates() -> [Date] {
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
}

// MARK: - Calendar Task Row
// MARK: - CalendarTaskRow aggiornata con colori categoria e layout a bandiera
struct CalendarTaskRow: View {
    let task: Task
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Colonna tempo fissa a sinistra
            Text(DateFormatter.timeOnly.string(from: task.date))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
                .frame(width: 50, alignment: .trailing)
                .padding(.top, 12)
            
            Spacer()
                .frame(width: 12)
            
            // Task Card con layout a bandiera
            HStack(spacing: 0) {
                // Barra verticale con colore categoria
                Rectangle()
                    .fill(task.category.color)
                    .frame(width: 3)
                    .cornerRadius(1.5)
                
                // Contenuto task
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(task.isCompleted ? .gray.opacity(0.6) : .appDarkBlue)
                        .strikethrough(task.isCompleted)
                    
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.system(size: 13))
                            .foregroundColor(task.isCompleted ? .gray.opacity(0.5) : .appDarkBlue.opacity(0.75))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(task.isCompleted ? Color.gray.opacity(0.1) : Color.appBeige)
                .cornerRadius(12)
            }
            .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
            .padding(.trailing)
        }
        .padding(.horizontal)
        .padding(.bottom, isLast ? 20 : 8)
    }
}




// MARK: - AddTaskView aggiornata con suggerimenti
struct AddTaskView: View {
    @ObservedObject var taskManager: TaskManager
    @State private var taskName = ""
    @State private var taskDescription = ""
    @State private var taskDate = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
    @State private var selectedCategory: TaskCategory = .general
    @State private var showingAlert = false
    @State private var showSuggestions = false
    
    var suggestedTasks: [String] {
        taskManager.getSuggestedTasks()
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("New Task")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.appDarkBlue)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 15) {
                    
                    // Suggerimenti basati sugli interessi
                    if !suggestedTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("Suggestions")
                                    .font(.caption)
                                    .foregroundColor(.appDarkBlue)
                                Button(action: { showSuggestions.toggle() }) {
                                    Image(systemName: showSuggestions ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.appLightBlue)
                                }
                            }
                            
                            if showSuggestions {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(suggestedTasks.prefix(5), id: \.self) { suggestion in
                                            Button(action: {
                                                taskName = suggestion
                                                showSuggestions = false
                                            }) {
                                                Text(suggestion)
                                                    .font(.caption)
                                                    .foregroundColor(.appDarkBlue)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(Color.appLightBlue.opacity(0.2))
                                                    )
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 2)
                                }
                            }
                        }
                    }
                    
                    // Nome
                    labelAndField("Name", text: $taskName, placeholder: "Enter task name")
                    
                    // Descrizione
                    labelAndField("Description", text: $taskDescription, placeholder: "Brief description", multiline: true)
                    
                    // Data & Ora
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Date & Time")
                            .font(.caption)
                            .foregroundColor(.appDarkBlue)
                        
                        DatePicker("", selection: $taskDate, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                            .datePickerStyle(WheelDatePickerStyle())
                            .accentColor(.appDarkBlue)
                            .environment(\.locale, Locale(identifier: "en_US_POSIX"))
                            .onChange(of: taskDate) { newValue in
                                taskDate = clampedDateToWorkHours(date: newValue)
                            }
                    }
                    
                    // Categoria
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Category")
                            .font(.caption)
                            .foregroundColor(.appDarkBlue)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(TaskCategory.allCases, id: \.self) { category in
                                    Button(action: {
                                        selectedCategory = category
                                    }) {
                                        Text(category.rawValue)
                                            .font(.caption)
                                            .foregroundColor(selectedCategory == category ? .white : category.color)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(selectedCategory == category ? category.color : category.color.opacity(0.2))
                                            )
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Pulsante Aggiunta
                Button(action: createTask) {
                    Text("Create Task")
                        .font(.headline)
                        .foregroundColor(.appBeige)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.appDarkBlue)
                        )
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .alert("Task Created!", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {
                clearForm()
            }
        } message: {
            Text("Your task has been added successfully!")
        }
    }
    
    // Resto delle funzioni helper rimangono uguali...
    private func createTask() {
        guard !taskName.isEmpty else { return }
        let newTask = Task(
            name: taskName,
            description: taskDescription,
            date: clampedDateToWorkHours(date: taskDate),
            category: selectedCategory
        )
        taskManager.addTask(newTask)
        showingAlert = true
    }
    
    private func clearForm() {
        taskName = ""
        taskDescription = ""
        taskDate = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
        selectedCategory = .general
    }
    
    private func clampedDateToWorkHours(date: Date) -> Date {
        let hour = Calendar.current.component(.hour, from: date)
        let clampedHour = min(max(hour, 8), 20)
        return Calendar.current.date(bySettingHour: clampedHour, minute: 0, second: 0, of: date) ?? date
    }
    
    @ViewBuilder
    private func labelAndField(_ label: String, text: Binding<String>, placeholder: String, multiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.caption)
                .foregroundColor(.appDarkBlue)
            if multiline {
                TextEditor(text: text)
                    .frame(height: 80)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.appDarkBlue)
                    .cornerRadius(8)
            } else {
                TextField(placeholder, text: text)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.appDarkBlue)
                    .cornerRadius(8)
            }
        }
    }
}


// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.gray.opacity(0.1))
            .foregroundColor(.appDarkBlue)
            .cornerRadius(8)
    }
}

// MARK: - Profile View
// MARK: - ProfileView aggiornata con nickname e interessi
struct ProfileView: View {
    @ObservedObject var taskManager: TaskManager
    @State private var tempNickname = ""
    @State private var showingInterests = false
    @State private var tempSelectedInterests: [String] = []
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("Profile")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.appDarkBlue)
                        .padding(.top)
                    
                    // Sezione Nickname
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nickname")
                            .font(.headline)
                            .foregroundColor(.appDarkBlue)
                        
                        HStack {
                            TextField("Enter your nickname", text: $tempNickname)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button("Save") {
                                taskManager.updateNickname(tempNickname)
                            }
                            .foregroundColor(.appDarkBlue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.appLightBlue.opacity(0.2))
                            )
                        }
                        
                        if !taskManager.userProgress.nickname.isEmpty {
                            Text("Current: \(taskManager.userProgress.nickname)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.appBeige.opacity(0.3))
                    )
                    .padding(.horizontal)
                    
                    // Sezione Interessi
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Interests")
                                .font(.headline)
                                .foregroundColor(.appDarkBlue)
                            Spacer()
                            Button(showingInterests ? "Done" : "Edit") {
                                if showingInterests {
                                    taskManager.updateInterests(tempSelectedInterests)
                                } else {
                                    tempSelectedInterests = taskManager.userProgress.selectedInterests
                                }
                                showingInterests.toggle()
                            }
                            .foregroundColor(.appDarkBlue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.appLightBlue.opacity(0.2))
                            )
                        }
                        
                        if showingInterests {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(predefinedInterests, id: \.self) { interest in
                                    let isSelected = tempSelectedInterests.contains(interest)
                                    
                                    Button(action: {
                                        if isSelected {
                                            tempSelectedInterests.removeAll { $0 == interest }
                                        } else {
                                            tempSelectedInterests.append(interest)
                                        }
                                    }) {
                                        Text(interest)
                                            .font(.caption)
                                            .foregroundColor(isSelected ? .white : .appDarkBlue)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(isSelected ? Color.appDarkBlue : Color.gray.opacity(0.2))
                                            )
                                    }
                                }
                            }
                        } else {
                            if taskManager.userProgress.selectedInterests.isEmpty {
                                Text("No interests selected")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } else {
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 8) {
                                    ForEach(taskManager.userProgress.selectedInterests, id: \.self) { interest in
                                        Text(interest)
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.appLightBlue)
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.appBeige.opacity(0.3))
                    )
                    .padding(.horizontal)
                    
                    // Progress Circle (esistente)
                    VStack {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                                .frame(width: 150, height: 150)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(min(taskManager.userProgress.totalTasksCompleted, 100)) / 100.0)
                                .stroke(Color.appLightBlue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 150, height: 150)
                                .rotationEffect(.degrees(-90))
                            
                            Text("\(taskManager.userProgress.totalTasksCompleted)")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.appDarkBlue)
                        }
                        
                        Text("Tasks Completed")
                            .font(.headline)
                            .foregroundColor(.appDarkBlue)
                    }
                    
                    // Stats (esistenti)
                    VStack(spacing: 15) {
                        StatRow(title: "Current Streak", value: "\(taskManager.userProgress.streakDays) days")
                        StatRow(title: "Total Time", value: formatTime(taskManager.userProgress.totalTimeSpent))
                        StatRow(title: "Tasks This Week", value: "\(getTasksThisWeek())")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.appBeige)
                    )
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            tempNickname = taskManager.userProgress.nickname
            tempSelectedInterests = taskManager.userProgress.selectedInterests
        }
    }
    
    // Funzioni helper esistenti...
    private func getTasksThisWeek() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
        
        return taskManager.tasks.filter { task in
            task.date >= startOfWeek && task.date <= endOfWeek && task.isCompleted
        }.count
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.appBeige)
            Spacer()
            Text(value)
                .foregroundColor(.appLightBlue)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Date Formatters
// MARK: - Date Formatters aggiornati
extension DateFormatter {
    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()
    
    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    static let currentMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    static let dayName: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()
}




// MARK: - Aggiornamento TaskManager con funzioni per rimozione e completamento
extension TaskManager {
    func removeTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks.remove(at: index)
            saveTasks()
        }
    }
    
    func toggleTaskCompletion(_ taskId: UUID) {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            tasks[index].isCompleted.toggle()
            if tasks[index].isCompleted {
                userProgress.totalTasksCompleted += 1
                userProgress.totalTimeSpent += tasks[index].duration
                updateStreak()
            } else {
                userProgress.totalTasksCompleted = max(0, userProgress.totalTasksCompleted - 1)
                userProgress.totalTimeSpent = max(0, userProgress.totalTimeSpent - tasks[index].duration)
            }
            saveTasks()
            saveProgress()
        }
    }
    
    func updateNickname(_ nickname: String) {
        userProgress.nickname = nickname
        saveProgress()
    }
    
    func updateInterests(_ interests: [String]) {
        userProgress.selectedInterests = interests
        saveProgress()
    }
    
    func getSuggestedTasks() -> [String] {
        var suggestions: [String] = []
        
        for interest in userProgress.selectedInterests {
            switch interest {
            case "Programming":
                suggestions.append(contentsOf: ["Code review", "Learn new framework", "Debug issue"])
            case "Design":
                suggestions.append(contentsOf: ["Create mockup", "Design system update", "UI research"])
            case "Reading":
                suggestions.append(contentsOf: ["Read chapter", "Book research", "Take notes"])
            case "Exercise":
                suggestions.append(contentsOf: ["Workout session", "Yoga practice", "Morning run"])
            case "Cooking":
                suggestions.append(contentsOf: ["Try new recipe", "Meal prep", "Kitchen organization"])
            default:
                suggestions.append("Practice \(interest)")
            }
        }
        
        return Array(Set(suggestions)) // Rimuove duplicati
    }
}







#Preview {
    ContentView()
}

