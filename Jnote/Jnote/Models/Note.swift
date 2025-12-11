import Foundation

struct Note: Codable, Identifiable, Equatable, Sendable {
    var id: UUID
    var userId: String
    var content: String
    var updatedAt: Date
    var createdAt: Date

    init(
        id: UUID = UUID(),
        userId: String,
        content: String = "",
        updatedAt: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.content = content
        self.updatedAt = updatedAt
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case content
        case updatedAt = "updated_at"
        case createdAt = "created_at"
    }
}
