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
                                        
                                        // Header giorno compatto e leggibile
                                        
                                        HStack(spacing: 6) {
                                            Text(dayName(from: day).uppercased()) // Abbreviazione in MAIUSCOLO
                                                .font(.system(size: 16, weight: .light))
                                                .foregroundColor(.appBeige)

                                            Text("\(Calendar.current.component(.day, from: day))")
                                                .font(.system(size: 30, weight: .bold))
                                                .foregroundColor(.appBeige)

                                            // Linea orizzontale subito a destra del numero
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


                                        // Tasks del giorno
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


