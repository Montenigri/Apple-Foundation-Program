import Foundation

struct UserProfile: Codable {
    var nickname: String = ""
    var completedTasks: Int = 0
    var totalHours: Double = 0
    var sleepStart: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    var sleepEnd: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    var workStart: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    var workEnd: Date = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
}
