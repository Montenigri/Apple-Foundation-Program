import SwiftUI

struct MyTimeView: View {
    @EnvironmentObject var taskManager: TaskManager
    @State private var selectedTask: Task?
    @State private var showDetail = false
    @State private var currentHeaderMonth = Date()
    @State private var hasScrolledToToday = false

    let daysRange = -30..<120

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                Color.appBlack.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header fisso con mese corrente
                    VStack(alignment: .leading, spacing: 8) {
                        Text(monthYearString(from: currentHeaderMonth))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.appBeige)

                        Rectangle()
                            .fill(Color.appDarkBlue.opacity(0.3))
                            .frame(height: 2)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .background(Color.appBlack)

                    // ScrollViewReader per scroll programmato
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 24) {
                                ForEach(daysRange, id: \.self) { offset in
                                    let day = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
                                    let tasks = taskManager.getTasksForDate(day)
                                    let isToday = Calendar.current.isDateInToday(day)
                                    VStack(alignment: .leading, spacing: 0) {
                                        
                                        // Header del mese se diverso dal precedente
                                        if offset == daysRange.first || shouldShowMonthHeader(for: day, previousDay: Calendar.current.date(byAdding: .day, value: offset - 1, to: Date())!) {
                                            HStack {
                                                Text(monthYearString(from: day))
                                                    .font(.title3)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.appBeige)
                                                    .padding(.vertical, 12)
                                                    .padding(.horizontal)
                                                Spacer()
                                            }
                                            .background(
                                                GeometryReader { geometry in
                                                    Color.clear
                                                        .onAppear {
                                                            updateHeaderMonth(for: day, geometry: geometry)
                                                        }
                                                        .onChange(of: day) { _, newDay in
                                                            updateHeaderMonth(for: newDay, geometry: geometry)
                                                        }
                                                }
                                            )
                                        }
                                        
                                        // Header giorno compatto e leggibile
                                        HStack(spacing: 6) {
                                            Text(dayName(from: day).uppercased()) // Abbreviazione in MAIUSCOLO
                                                .font(.system(size: 16, weight: .light))
                                                .foregroundColor(tasks.isEmpty ? .appBeige.opacity(0.5) : .appBeige)

                                            Text("\(Calendar.current.component(.day, from: day))")
                                                .font(.system(size: 30, weight: .bold))
                                                .foregroundColor(tasks.isEmpty ? .appBeige.opacity(0.5) : .appBeige)

                                            // Linea orizzontale subito a destra del numero
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

                                        // Tasks del giorno (se presenti)
                                        if !tasks.isEmpty {
                                            ForEach(tasks.sorted(by: { $0.startTime < $1.startTime })) { task in
                                                TaskRowView(task: task) {
                                                    selectedTask = task
                                                    showDetail = true
                                                }

                                                .padding(.horizontal, 16)
                                                .padding(.bottom, 16) // spazio tra i task
                                                .contentShape(Rectangle())
                                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                                    Button(role: .destructive) {
                                                        taskManager.removeTask(task)
                                                    } label: {
                                                        Label("Elimina", systemImage: "trash")
                                                    }
                                                }
                                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                                    Button {
                                                        taskManager.toggleTaskCompletion(task)
                                                    } label: {
                                                        if task.isCompleted {
                                                            Label("Da completare", systemImage: "arrow.uturn.left")
                                                        } else {
                                                            Label("Completato", systemImage: "checkmark")
                                                        }
                                                    }
                                                    .tint(task.isCompleted ? .orange : .green)
                                                }
                                            }
                                        } else {
                                            // Placeholder per giorno vuoto
                                            Text("Nessun impegno")
                                                .font(.caption)
                                                .foregroundColor(.appBeige.opacity(0.4))
                                                .padding(.horizontal)
                                                .padding(.bottom, 8)
                                        }
                                    }
                                    .id(isToday ? "today" : "day_\(offset)")
                                }
                            }
                            .padding(.top, 16)
                            .onAppear {
                                if !hasScrolledToToday {
                                    withAnimation(.easeInOut(duration: 0.7)) {
                                        proxy.scrollTo("today", anchor: .center)
                                    }
                                    hasScrolledToToday = true
                                }
                            }
                        }
                    }
                }
            }
            .sheet(item: $selectedTask) { task in
                TaskDetailView(task: task) {
                    selectedTask = nil
                }
                .environmentObject(taskManager)
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
    
    private func updateHeaderMonth(for day: Date, geometry: GeometryProxy) {
        let frame = geometry.frame(in: .global)
        // Se il header del mese è vicino alla parte superiore dello schermo
        if frame.minY <= 120 { // Soglia di attivazione
            currentHeaderMonth = day
        }
    }

    private func currentMonthEnglish() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: Date())
    }

    private func dayName(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // Esempio: "Wed"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}



#Preview{
    MyTimeView().environmentObject(TaskManager())
}


