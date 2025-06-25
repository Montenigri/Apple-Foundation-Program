import SwiftUI

struct TaskRowView: View {
    let task: Task
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Barra priorità/suggerimento
                Rectangle()
                    .fill(task.isSuggested ? Color.appLightBlue : Color.appDarkBlue)
                    .frame(width: 4)
                    .cornerRadius(2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.name)
                        .font(.headline)
                        .foregroundColor(.appDarkBlue)
                        .multilineTextAlignment(.leading)

                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.caption)
                            .foregroundColor(.appDarkBlue.opacity(0.7))
                            .multilineTextAlignment(.leading)
                    }

                    HStack {
                        Text(timeString(from: task.startTime))
                            .font(.caption)
                            .foregroundColor(.appDarkBlue.opacity(0.7))

                        if !task.location.isEmpty {
                            Text("• \(task.location)")
                                .font(.caption)
                                .foregroundColor(.appDarkBlue.opacity(0.7))
                        }
                    }
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(task.isCompleted ? Color.appBeige.opacity(0.3) : Color.appBeige)
            )
            .opacity(task.isCompleted ? 0.5 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}