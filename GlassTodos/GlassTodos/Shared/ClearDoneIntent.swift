import AppIntents

// MARK: - Clear Done Intent
// Used by the widget's "clear completed" button.

struct ClearDoneIntent: AppIntent {

    static var title: LocalizedStringResource = "Clear Completed"
    static var description: IntentDescription = "Removes all completed tasks."

    func perform() async throws -> some IntentResult {
        TodoStore.clearDone()
        return .result()
    }
}
