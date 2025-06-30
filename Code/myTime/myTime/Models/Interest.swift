import Foundation

struct Interest: Identifiable, Codable {
    var id: UUID
    var name: String
    var duration: TimeInterval
    var preferenceLevel: Int // 1-5 scale
    var timeSlot: String
    
    init(id: UUID = UUID(), name: String, duration: TimeInterval, preferenceLevel: Int, timeSlot: String) {
        self.id = id
        self.name = name
        self.duration = duration
        self.preferenceLevel = preferenceLevel
        self.timeSlot = timeSlot
    }
}
