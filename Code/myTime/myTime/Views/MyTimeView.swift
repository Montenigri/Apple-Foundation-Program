import SwiftUI

struct MyTimeView: View {
    @EnvironmentObject var taskManager: TaskManager
    @State private var selectedTask: Task?
    @State private var showDetail = false
    @State private var currentHeaderMonth = Date()
    @State private var hasScrolledToToday = false
    @State private var showEasterEgg = false
    @State private var monthTapCount = 0

    let daysRange = -30..<120

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                Color.appBlack.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header fisso con mese corrente
                    headerSection
                    
                    // ScrollViewReader per scroll programmato
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 24) {
                                ForEach(daysRange, id: \.self) { offset in
                                    daySection(offset: offset, proxy: proxy)
                                }
                            }
                            .padding(.top, 16)
                            .onAppear {
                                scrollToTodayIfNeeded(proxy: proxy)
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .coordinateSpace(name: "scroll")
                    }
                }
            }
            .onAppear {
                taskManager.recalculateSuggestionsForNextThreeDays()
            }
            .sheet(item: $selectedTask) { task in
                TaskDetailView(task: task) {
                    selectedTask = nil
                }
                .environmentObject(taskManager)
            }
            .sheet(isPresented: $showEasterEgg) {
                EasterEggView()
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(monthYearString(from: currentHeaderMonth))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.appBeige)
                .onTapGesture {
                    monthTapCount += 1
                    if monthTapCount == 5 {
                        showEasterEgg = true
                        monthTapCount = 0
                    }
                }
            Rectangle()
                .fill(Color.appDarkBlue.opacity(0.3))
                .frame(height: 2)
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .background(Color.appBlack)
    }
    
    private func daySection(offset: Int, proxy: ScrollViewProxy) -> some View {
        let day = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
        let tasks = taskManager.getTasksForDate(day)
        let isToday = Calendar.current.isDateInToday(day)
        
        return VStack(alignment: .leading, spacing: 0) {
            // Month header se necessario
            if shouldShowMonthHeader(offset: offset, day: day) {
                monthHeaderView(day: day)
            }
            
            // Day header
            dayHeaderView(day: day, tasks: tasks, isToday: isToday)
            
            // Tasks section
            if !tasks.isEmpty {
                tasksListView(tasks: tasks)
            } else {
                emptyDayView()
            }
        }
        .id(isToday ? "today" : "day_\(offset)")
        .background(
            // GeometryReader per tracciare la posizione durante lo scroll
            GeometryReader { geometry in
                Color.clear
                    .preference(key: ScrollOffsetPreferenceKey.self, value: [
                        ScrollOffsetData(
                            day: day,
                            offset: geometry.frame(in: .named("scroll")).minY
                        )
                    ])
            }
        )
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { preferences in
            updateHeaderForVisibleMonth(preferences: preferences)
        }
    }
    
    private func shouldShowMonthHeader(offset: Int, day: Date) -> Bool {
        if offset == daysRange.first { return true }
        
        let previousDay = Calendar.current.date(byAdding: .day, value: offset - 1, to: Date())!
        return shouldShowMonthHeader(for: day, previousDay: previousDay)
    }
    
    private func monthHeaderView(day: Date) -> some View {
        HStack {
            Text(monthYearString(from: day))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.appBeige)
                .padding(.vertical, 12)
                .padding(.horizontal)
            Spacer()
        }
    }
    
    private func dayHeaderView(day: Date, tasks: [Task], isToday: Bool) -> some View {
        HStack(spacing: 6) {
            Text(dayName(from: day).uppercased())
                .font(.system(size: 16, weight: .light))
                .foregroundColor(tasks.isEmpty ? .appBeige.opacity(0.5) : .appBeige)

            // Numero del giorno con evidenziazione sottile per oggi
            ZStack {
                if isToday {
                    // Contorno squadrato con bordi arrotondati
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.appBeige, lineWidth: 2)
                        .frame(width: 36, height: 32)
                        .animation(.easeInOut(duration: 0.5), value: isToday)
                }
                
                Text("\(Calendar.current.component(.day, from: day))")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(
                        isToday ? .appBeige : // Stesso colore beige per coerenza
                        (tasks.isEmpty ? .appBeige.opacity(0.5) : .appBeige)
                    )
            }

            // Linea orizzontale
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: (tasks.isEmpty ? Color.appBeige.opacity(0.3) : Color.appBeige).opacity(1.0), location: 0),
                            .init(color: (tasks.isEmpty ? Color.appBeige.opacity(0.3) : Color.appBeige).opacity(0.0), location: 1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, tasks.isEmpty ? 8 : 12)
    }
    
    private func tasksListView(tasks: [Task]) -> some View {
        let taskCount = tasks.count
        let baseHeight: CGFloat = 80
        let maxVisibleTasks = 30
        let maxHeight: CGFloat = CGFloat(maxVisibleTasks) * baseHeight
        let shouldScroll = taskCount > maxVisibleTasks
        let listHeight = taskCount > 0 ? max(shouldScroll ? maxHeight : CGFloat(taskCount) * baseHeight, baseHeight) : 0

        return List {
            ForEach(tasks.sorted(by: { $0.startTime < $1.startTime })) { task in
                TaskRowView(task: task) {
                    selectedTask = task
                    showDetail = true
                }
                .padding(.horizontal, 12) // ✅ padding interno ai task
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)) // ✅ elimina padding List nativo
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            taskManager.removeTask(task)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            taskManager.toggleTaskCompletion(task)
                        }
                    } label: {
                        if task.isCompleted {
                            Label("To do", systemImage: "arrow.uturn.left")
                        } else {
                            Label("Done", systemImage: "checkmark")
                        }
                    }
                    .tint(task.isCompleted ? .orange : .green)
                }
            }
        }
        .frame(height: listHeight)
        .scrollDisabled(!shouldScroll)
        .listStyle(.plain)
        .background(Color.clear)
    }

    
    private func emptyDayView() -> some View {
        Text("No tasks")
            .font(.caption)
            .foregroundColor(.appBeige.opacity(0.4))
            .padding(.horizontal)
            .padding(.bottom, 8)
    }
    
    // MARK: - Helper Methods
    
    private func scrollToTodayIfNeeded(proxy: ScrollViewProxy) {
        if !hasScrolledToToday {
            withAnimation(.easeInOut(duration: 0.7)) {
                proxy.scrollTo("today", anchor: .center)
            }
            hasScrolledToToday = true
        }
    }
    
    private func updateHeaderForVisibleMonth(preferences: [ScrollOffsetData]) {
        // Trova il giorno più vicino al top dello schermo (considerando l'header fisso)
        let headerHeight: CGFloat = 120
        
        // Filtra solo i giorni che sono visibili nella parte superiore dello schermo
        let visibleDays = preferences.filter { data in
            data.offset >= -headerHeight && data.offset <= headerHeight * 2
        }
        
        // Trova il giorno più vicino al top
        if let closestData = visibleDays.min(by: { abs($0.offset + headerHeight) < abs($1.offset + headerHeight) }) {
            let dayMonth = Calendar.current.component(.month, from: closestData.day)
            let dayYear = Calendar.current.component(.year, from: closestData.day)
            let currentMonth = Calendar.current.component(.month, from: currentHeaderMonth)
            let currentYear = Calendar.current.component(.year, from: currentHeaderMonth)
            
            if dayMonth != currentMonth || dayYear != currentYear {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentHeaderMonth = closestData.day
                }
            }
        }
    }

    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }
    
    private func shouldShowMonthHeader(for currentDay: Date, previousDay: Date) -> Bool {
        let currentMonth = Calendar.current.component(.month, from: currentDay)
        let currentYear = Calendar.current.component(.year, from: currentDay)
        let previousMonth = Calendar.current.component(.month, from: previousDay)
        let previousYear = Calendar.current.component(.year, from: previousDay)
        
        return currentMonth != previousMonth || currentYear != previousYear
    }

    private func dayName(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preference Key per tracciare la posizione dello scroll

struct ScrollOffsetData: Equatable {
    let day: Date
    let offset: CGFloat
    
    static func == (lhs: ScrollOffsetData, rhs: ScrollOffsetData) -> Bool {
        return lhs.day == rhs.day && lhs.offset == rhs.offset
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: [ScrollOffsetData] = []
    
    static func reduce(value: inout [ScrollOffsetData], nextValue: () -> [ScrollOffsetData]) {
        value.append(contentsOf: nextValue())
    }
}
