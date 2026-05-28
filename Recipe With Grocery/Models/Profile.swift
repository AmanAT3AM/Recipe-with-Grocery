import Foundation

struct Profile: Codable, Hashable, Identifiable {
    let id: UUID
    let name: String
    let email: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case createdAt = "created_at"
    }
}
