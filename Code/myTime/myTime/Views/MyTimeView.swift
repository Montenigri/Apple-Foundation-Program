import SwiftUI

struct MyTimeView: View {
    @EnvironmentObject var taskManager: TaskManager
    @State private var selectedTask: Task?

    var body: some View {
        ZStack {
            Color.appBlack.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header: Mese Anno
                Text(currentMonth())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.appBeige)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                // Barra orizzontale separatrice
                Rectangle()
                    .fill(Color.appDarkBlue)
                    .frame(height: 2)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 4)

                // Giorno abbreviazione (in inglese)
                Text(currentWeekdayAbbreviation())
                    .font(.headline)
                    .foregroundColor(.appBeige)
                    .padding(.horizontal, 20)

                // Giorno numero
                Text(currentDay())
                    .font(.headline)
                    .foregroundColor(.appBeige)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)

                // Lista Task con swipe
                List {
                    ForEach(sortedTasks()) { task in
                        HStack(alignment: .top, spacing: 12) {
                            // Barretta verticale orario
                            VStack {
                                Rectangle()
                                    .fill(Color.appLightBlue)
                                    .frame(width: 4, height: 50)
                                    .cornerRadius(2)
                                Spacer()
                            }
                            .padding(.top, 8)

                            // Riquadro task
                            VStack(alignment: .leading, spacing: 4) {
                                Text(timeString(from: task.startTime))
                                    .font(.caption)
                                    .foregroundColor(.appLightBlue)
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
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTask = task
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            // Elimina task (da destra verso sinistra)
                            Button(role: .destructive) {
                                taskManager.removeTask(task)
                            } label: {
                                Label("Elimina", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            // Completa/Da completare (da sinistra verso destra)
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
                }
                .listStyle(.plain)
                .background(Color.clear)
            }
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task) {
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

    private func currentWeekdayAbbreviation() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: Date())
    }

    private func currentDay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: Date())
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}