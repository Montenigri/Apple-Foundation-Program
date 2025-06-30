import Foundation

struct Task: Identifiable, Codable {
    var id: UUID
    var name: String
    var description: String
    var duration: TimeInterval
    var location: String
    var startTime: Date
    var isCompleted: Bool
    var isSuggested: Bool
    var estimatedTime: Double {
        return duration / 3600
    }

    var endTime: Date {
        return startTime.addingTimeInterval(duration)
    }

    init(id: UUID = UUID(), name: String, description: String, duration: TimeInterval, location: String, startTime: Date, isCompleted: Bool = false, isSuggested: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.duration = duration
        self.location = location
        self.startTime = startTime
        self.isCompleted = isCompleted
        self.isSuggested = isSuggested
    }
}
