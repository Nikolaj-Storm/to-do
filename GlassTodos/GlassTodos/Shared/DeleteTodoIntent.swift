import AppIntents

// MARK: - Delete Todo Intent
// Used by the widget's swipe‑to‑delete or trash button.

struct DeleteTodoIntent: AppIntent {

    static var title: LocalizedStringResource = "Delete Todo"
    static var description: IntentDescription = "Removes a task from the list."

    @Parameter(title: "Item ID")
    var itemID: String

    init() {}

    init(itemID: String) {
        self.itemID = itemID
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: itemID) else { return .result() }
        TodoStore.deleteItem(id: uuid)
        return .result()
    }
}
