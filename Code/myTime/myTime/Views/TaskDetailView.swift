import SwiftUI

struct TaskDetailView: View {
    let task: Task
    let onDelete: () -> Void
    @EnvironmentObject var taskManager: TaskManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBlack.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header con pulsante chiudi
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
                    
                    // Titolo centrato
                    VStack(spacing: 15) {
                        Text("Dettagli Task")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.appBeige)
                    }
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(task.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.appBeige)

                                if !task.description.isEmpty {
                                    Text(task.description)
                                        .font(.body)
                                        .foregroundColor(.appBeige.opacity(0.8))
                                }

                                HStack {
                                    Text("Inizio: \(timeString(from: task.startTime))")
                                        .font(.subheadline)
                                        .foregroundColor(.appLightBlue)

                                    Spacer()

                                    Text("Fine: \(timeString(from: task.endTime))")
                                        .font(.subheadline)
                                        .foregroundColor(.appLightBlue)
                                }

                                if !task.location.isEmpty {
                                    Text("Luogo: \(task.location)")
                                        .font(.subheadline)
                                        .foregroundColor(.appBeige.opacity(0.8))
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.appDarkBlue.opacity(0.3))
                            )

                            Spacer()
                        }
                        .padding()
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .alert("Conferma rimozione", isPresented: $showingDeleteAlert) {
            Button("Annulla", role: .cancel) { }
            Button("Rimuovi", role: .destructive) { [taskManager] in
                taskManager.removeTask(task)
                onDelete()
                dismiss()
            }
        } message: {
            Text("Sei sicuro di voler rimuovere questo task?")
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
