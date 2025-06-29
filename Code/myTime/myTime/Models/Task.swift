import Foundation

struct Task: Identifiable, Codable {
    let id = UUID()
    var name: String
    var description: String
    var duration: TimeInterval
    var location: String
    var startTime: Date
    var isCompleted: Bool = false
    var isSuggested: Bool = false
    var estimatedTime: Double {
        return duration / 3600
    }

    var endTime: Date {
        return startTime.addingTimeInterval(duration)
    }
}
