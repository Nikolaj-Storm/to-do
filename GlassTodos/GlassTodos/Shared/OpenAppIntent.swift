import AppIntents

// MARK: - Open App Intent
// Tapping "Edit in app" in the widget opens the main app for reordering / editing.

struct OpenAppIntent: AppIntent {

    static var title: LocalizedStringResource = "Open GlassTodos"
    static var description: IntentDescription = "Opens the main app for editing."
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}
