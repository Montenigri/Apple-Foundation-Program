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
                            Text("New Task")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.appBeige)

                            // Name field
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Task name")
                                    .font(.subheadline)
                                    .foregroundColor(.appBeige)
                                TextField("Insert Name", text: $name)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }

                            // Description field
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Description")
                                    .font(.subheadline)
                                    .foregroundColor(.appBeige)
                                TextField("Insert description", text: $description, axis: .vertical)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .lineLimit(3...6)
                            }

                            // Start time
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Start time")
                                    .font(.subheadline)
                                    .foregroundColor(.appBeige)
                                DatePicker("", selection: $startTime, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .colorScheme(.dark)
                            }


                            // Duration
                            DurationPickerView(totalMinutes: $duration)

                            // Location field
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Place")
                                    .font(.subheadline)
                                    .foregroundColor(.appBeige)
                                TextField("Add place", text: $location)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }

                            // Add button
                            Button("Add Task") {
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
        .alert("Warning", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private func addTask() {
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
            alertMessage = "There is already a task in this time slot."
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

            alertMessage = "Task added successfully!"
            showingAlert = true
        }
    }
    
    
    
    
    // MARK: - Duration Picker Component
    struct DurationPickerView: View {
        @Binding var totalMinutes: Int
        
        @State private var selectedHours: Int
        @State private var selectedMinutes: Int
        
        init(totalMinutes: Binding<Int>) {
            self._totalMinutes = totalMinutes
            let hours = totalMinutes.wrappedValue / 60
            let minutes = totalMinutes.wrappedValue % 60
            self._selectedHours = State(initialValue: hours)
            self._selectedMinutes = State(initialValue: minutes)
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 5) {
                Text("Duration")
                    .font(.subheadline)
                    .foregroundColor(.appBeige)
                
                HStack(spacing: 0) {
                    Spacer()
                    
                    // Hours Picker
                    VStack(spacing: 8) {
                        Text("Hours")
                            .font(.subheadline)
                            .foregroundColor(.appBeige)
                        
                        Picker("Hours", selection: $selectedHours) {
                            ForEach(0...23, id: \.self) { hour in
                                Text("\(hour)")
                                    .foregroundColor(.appBeige)
                                    .font(.system(size: 22, weight: .medium, design: .rounded))
                                    .tag(hour)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100, height: 150)
                    }
                    
                    Text(":")
                        .font(.largeTitle)
                        .fontWeight(.medium)
                        .foregroundColor(.appBeige)
                        .padding(.horizontal, 20)
                        .padding(.top, 30)
                    
                    // Minutes Picker
                    VStack(spacing: 8) {
                        Text("Minutes")
                            .font(.subheadline)
                            .foregroundColor(.appBeige)
                        
                        Picker("Minutes", selection: $selectedMinutes) {
                            ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) { minute in
                                Text(String(format: "%02d", minute))
                                    .foregroundColor(.appBeige)
                                    .font(.system(size: 22, weight: .medium, design: .rounded))
                                    .tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100, height: 150)
                    }
                    
                    Spacer()
                }
            }
            .onChange(of: selectedHours) { _, newHours in
                updateTotalMinutes()
            }
            .onChange(of: selectedMinutes) { _, newMinutes in
                updateTotalMinutes()
            }
        }
        
        private func updateTotalMinutes() {
            let total = selectedHours * 60 + selectedMinutes
            // Minimum 5 minutes
            totalMinutes = max(total, total == 0 ? 5 : total)
            
            // If total is 0, set to 5 minutes and update selectedMinutes
            if total == 0 {
                selectedMinutes = 5
            }
        }
    }
    
}
