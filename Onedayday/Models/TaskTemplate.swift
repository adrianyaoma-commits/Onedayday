import Foundation

struct TaskTemplate: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var important: Bool
    var urgent: Bool
    var device: String = "Mac"
    var description: String?
    var estimatedTime: String?
    var presetKey: String? = nil
}
