import AppIntents

// MARK: - Add Todo Intent
// Used by the widget's "+" button to create a new task.

struct AddTodoIntent: AppIntent {

    static var title: LocalizedStringResource = "Add Todo"
    static var description: IntentDescription = "Adds a new task to the list."

    func perform() async throws -> some IntentResult {
        TodoStore.addItem()
        return .result()
    }
}
