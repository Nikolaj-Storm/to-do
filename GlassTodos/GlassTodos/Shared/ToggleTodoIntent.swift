import AppIntents
import WidgetKit

// MARK: - Toggle Todo Intent
// Used by the widget's interactive checkmark buttons.

struct ToggleTodoIntent: AppIntent {

    static var title: LocalizedStringResource = "Toggle Todo"
    static var description: IntentDescription = "Marks a task as done or not done."

    // The UUID string of the item to toggle.
    @Parameter(title: "Item ID")
    var itemID: String

    init() {}

    init(itemID: String) {
        self.itemID = itemID
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: itemID) else { return .result() }
        TodoStore.toggleDone(id: uuid)
        return .result()
    }
}
