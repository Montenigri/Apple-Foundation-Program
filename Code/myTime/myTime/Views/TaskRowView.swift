import SwiftUI

struct TaskRowView: View {
    let task: Task
    let onTap: () -> Void
    let descriptionLimit: Int

    init(task: Task, descriptionLimit: Int = 30, onTap: @escaping () -> Void) {
        self.task = task
        self.descriptionLimit = descriptionLimit
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 0) {
                // Colonna oraria con inizio e fine
                VStack(alignment: .trailing, spacing: 4) {
                    Text(timeString(from: task.startTime))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.appLightBlue)

                    Text(timeString(from: task.endTime))
                        .font(.system(size: 11))
                        .foregroundColor(.appLightBlue.opacity(0.7))
                }
                .frame(width: 50, alignment: .trailing)
                .padding(.top, 12)

                Spacer().frame(width: 12)

                // Task Card
                HStack(spacing: 0) {
                    // Barra verticale
                    Rectangle()
                        .fill(task.isSuggested ? Color.appLightBlue : Color.appDarkBlue)
                        .frame(width: 3)
                        .cornerRadius(1.5)

                    // Contenuto
                    VStack(alignment: .leading, spacing: 6) {
                        Text(task.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(task.isCompleted ? .gray.opacity(0.6) : .appDarkBlue)
                            .strikethrough(task.isCompleted)
                            .layoutPriority(1)

                        if !task.description.isEmpty {
                            Text(truncated(task.description, limit: descriptionLimit))
                                .font(.caption)
                                .foregroundColor(.appDarkBlue.opacity(0.7))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }

                        if !task.location.isEmpty {
                            Text("📍 \(task.location)")
                                .font(.system(size: 11))
                                .foregroundColor(.appDarkBlue.opacity(0.5))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(
                        task.isCompleted ? Color.appBeige.opacity(0.3) : Color.appBeige
                    )
                    .cornerRadius(12)
                    .fixedSize(horizontal: false, vertical: false)
                }
                .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .buttonStyle(.plain)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func truncated(_ text: String, limit: Int) -> String {
        if text.count > limit {
            let index = text.index(text.startIndex, offsetBy: limit)
            return String(text[..<index]) + "..."
        } else {
            return text
        }
    }
}

