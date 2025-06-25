import SwiftUI

struct MyTimeView: View {
    @EnvironmentObject var taskManager: TaskManager
    @State private var selectedTask: Task?
    @State private var showDetail = false

    let daysRange = 0..<30

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                Color.appBlack.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header fisso con mese corrente
                    VStack(alignment: .leading, spacing: 8) {
                        Text(currentMonthEnglish())
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

                    // Contenuto scrollabile: giorni e task
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
                                                Text(dayName(from: day))
                                                    .font(.caption)
                                                    .foregroundColor(.appBeige.opacity(0.7))
                                                Text("\(Calendar.current.component(.day, from: day))")
                                                    .font(.title2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.appBeige)
                                            }
                                            .frame(width: 60, alignment: .leading)
                                            Spacer()
                                        }
                                        .padding(.horizontal)
                                        .padding(.bottom, 12)

                                        // Tasks del giorno
                                        ForEach(tasks.sorted(by: { $0.startTime < $1.startTime })) { task in
                                            HStack(alignment: .bottom, spacing: 12) {
                                                // Orario a sinistra
                                                Text(timeString(from: task.startTime))
                                                    .font(.caption2)
                                                    .foregroundColor(.appLightBlue)
                                                    .frame(width: 48, alignment: .leading)
                                                    .padding(.leading, 8)

                                                // Barretta verticale
                                                Rectangle()
                                                    .fill(Color.appLightBlue)
                                                    .frame(width: 4, height: 50)
                                                    .cornerRadius(2)

                                                // Card task
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(task.name)
                                                        .font(.headline)
                                                        .foregroundColor(.appDarkBlue)
                                                    if !task.description.isEmpty {
                                                        Text(task.description)
                                                            .font(.caption)
                                                            .foregroundColor(.appDarkBlue.opacity(0.7))
                                                    }
                                                }
                                                .padding()
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(task.isCompleted ? Color.appBeige.opacity(0.3) : Color.appBeige)
                                                )
                                                .opacity(task.isCompleted ? 0.5 : 1.0)
                                                Spacer()
                                            }
                                            .padding(.horizontal, 16)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                selectedTask = task
                                                showDetail = true
                                            }
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
                                    }
                                }
                            }
                        }
                        .padding(.top, 16)
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

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}