struct Interest: Identifiable, Codable {
    let id = UUID()
    var name: String
    var duration: TimeInterval
    var preferenceLevel: Int // 1-5 scale
    var timeSlot: String
}
