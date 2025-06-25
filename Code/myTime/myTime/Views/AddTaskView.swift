import SwiftUI

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