import SwiftUI

struct MyTimeView: View {
    @EnvironmentObject var taskManager: TaskManager
    @State private var selectedTask: Task?
    @State private var showDetail = false
    @State private var currentVisibleMonth: String = ""

    // Paging
    @State private var daysBefore = 15
    @State private var daysAfter = 15
    private let pageSize = 15

    struct DaySection: Identifiable {
        let id = UUID()
        let date: Date
        let isFirstOfMonth: Bool
    }

    var daySections: [DaySection] {
        var result: [DaySection] = []
        var lastMonth: Int? = nil
        var lastYear: Int? = nil
        for offset in (-daysBefore)...daysAfter {
            let day = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
            let month = Calendar.current.component(.month, from: day)
            let year = Calendar.current.component(.year, from: day)
            let isFirst = (month != lastMonth) || (year != lastYear)
            result.append(DaySection(date: day, isFirstOfMonth: isFirst))
            lastMonth = month
            lastYear = year
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                Color.appBlack.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header dinamico con mese corrente visibile
                    VStack(alignment: .leading, spacing: 8) {
                        Text(currentVisibleMonth.isEmpty ? currentMonthEnglish() : currentVisibleMonth)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.appBeige)
                            .id("HeaderMonth")

                        Rectangle()
                            .fill(Color.appDarkBlue.opacity(0.3))
                            .frame(height: 2)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .background(Color.appBlack)
                    .zIndex(1)


                    ScrollViewReader { scrollProxy in
                        ScrollView {
                            LazyVStack(spacing: 24, pinnedViews: []) {
                                ForEach(Array(daySections.enumerated()), id: \.element.id) { index, section in
                                    let day = section.date
                                    let tasks = taskManager.getTasksForDate(day)
                                    if section.isFirstOfMonth {
                                        Text(monthYearString(from: day))
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.appBeige)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.horizontal)
                                            .padding(.top, 10)
                                    }
                                    VStack(alignment: .leading, spacing: 0) {
                                        // Header giorno
                                        HStack(spacing: 6) {
                                            Text(dayName(from: day).uppercased())
                                                .font(.system(size: 16, weight: .light))
                                                .foregroundColor(.appBeige)
                                            Text("\(Calendar.current.component(.day, from: day))")
                                                .font(.system(size: 30, weight: .bold))
                                                .foregroundColor(.appBeige)
                                            Rectangle()
                                                .fill(
                                                    LinearGradient(
                                                        gradient: Gradient(stops: [
                                                            .init(color: Color.appBeige.opacity(1.0), location: 0),
                                                            .init(color: Color.appBeige.opacity(0.0), location: 1)
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
                                        .padding(.bottom, 12)

                                        // Lista task del giorno o messaggio vuoto
                                        if tasks.isEmpty {
                                            Text("Nessun impegno per questo giorno")
                                                .foregroundColor(.appBeige.opacity(0.5))
                                                .padding(.horizontal)
                                                .padding(.bottom, 24)
                                        } else {
                                            List {
                                                ForEach(tasks.sorted(by: { $0.startTime < $1.startTime })) { task in
                                                    TaskRowView(task: task, descriptionLimit: 60) {
                                                        selectedTask = task
                                                        showDetail = true
                                                    }
                                                    .padding(.vertical, 8)
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
                                                .listRowBackground(Color.clear)
                                                .listRowSeparator(.hidden)
                                            }
                                            .listStyle(.plain)
                                            .frame(height: CGFloat(tasks.count) * 80)
                                            .background(Color.clear)
                                        }
                                    }
                                    // Paging logic invariata
                                    if index == 2 {
                                        Color.clear
                                            .frame(height: 1)
                                            .onAppear {
                                                if daysBefore < 365 {
                                                    daysBefore += pageSize
                                                }
                                            }
                                    }
                                    if index == daySections.count - 3 {
                                        Color.clear
                                            .frame(height: 1)
                                            .onAppear {
                                                if daysAfter < 365 {
                                                    daysAfter += pageSize
                                                }
                                            }
                                    }
                                }
                            }
                            .padding(.top, 16)
                        }
                        .coordinateSpace(name: "scroll")
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

    private func currentMonthEnglish() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: Date())
    }

    private func dayName(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }
}