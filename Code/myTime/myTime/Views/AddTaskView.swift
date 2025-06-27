import SwiftUI

struct AddTaskView: View {
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var duration = Int(30)
    @State private var location = ""
    @State private var startTime = Date()
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        ZStack {
            Color.appBlack.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .foregroundColor(.appBeige)
                            .padding(.top, 8)
                            .padding(.trailing, 8)
                    }
                }
                .zIndex(1)
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
                            Section(header: Text("Durata (minuti)").foregroundColor(.appBeige)) {
                                Stepper("\(duration) minuti", value: $duration, in: 5...180, step: 5)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.appBeige)
                                    )
                                    .foregroundColor(.appBlack)
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
        }
        .alert("Attenzione", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private func addTask() {
        let calendar = Calendar.current
        let durationInSeconds = TimeInterval(duration * 60)

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
            duration = 30
            location = ""
            startTime = Date()

            alertMessage = "Task aggiunto con successo!"
            showingAlert = true
        }
    }
}