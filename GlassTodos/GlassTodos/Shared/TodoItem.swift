import Foundation

// MARK: - Todo Item Model
// Shared between the main app and the widget extension.

struct TodoItem: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var isDone: Bool
    var position: Int

    init(id: UUID = UUID(), title: String, isDone: Bool = false, position: Int = 0) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.position = position
    }
}
