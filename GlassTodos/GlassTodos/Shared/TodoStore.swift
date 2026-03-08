import Foundation
import WidgetKit

// MARK: - Todo Store
// Persists items via App Group UserDefaults so both the app and widget can access them.
//
// ┌─────────────────────────────────────────────────────────┐
// │  APP GROUP SETUP                                        │
// │                                                         │
// │  1. In Xcode, select each target (GlassTodos AND        │
// │     GlassTodosWidgetExtension).                         │
// │  2. Go to Signing & Capabilities → + Capability →       │
// │     App Groups.                                         │
// │  3. Add: group.com.yourname.GlassTodos                  │
// │  4. Make sure both targets use the SAME group ID.        │
// │                                                         │
// │  To change the identifier, update `appGroupID` below.   │
// └─────────────────────────────────────────────────────────┘

final class TodoStore {

    // ── Change this to your own App Group identifier ──
    static let appGroupID = "group.com.yourname.GlassTodos"

    private static let storeKey = "glass_todos_items"

    // MARK: - Read

    static func load() -> [TodoItem] {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: storeKey),
              let items = try? JSONDecoder().decode([TodoItem].self, from: data)
        else {
            return Self.sampleItems()
        }
        return items.sorted { $0.position < $1.position }
    }

    // MARK: - Write

    static func save(_ items: [TodoItem]) {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = try? JSONEncoder().encode(items)
        else { return }
        defaults.set(data, forKey: storeKey)

        // Tell WidgetKit to refresh the timeline so the widget updates immediately.
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Convenience mutations

    static func toggleDone(id: UUID) {
        var items = load()
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].isDone.toggle()
        save(items)
    }

    static func addItem(title: String = "New task") {
        var items = load()
        let maxPos = items.map(\.position).max() ?? -1
        items.append(TodoItem(title: title, position: maxPos + 1))
        save(items)
    }

    static func deleteItem(id: UUID) {
        var items = load()
        items.removeAll { $0.id == id }
        reindex(&items)
        save(items)
    }

    static func reindex(_ items: inout [TodoItem]) {
        items.sort { $0.position < $1.position }
        for i in items.indices { items[i].position = i }
    }

    // MARK: - Defaults

    /// Shown on first launch so the widget isn't empty.
    private static func sampleItems() -> [TodoItem] {
        [
            TodoItem(title: "Buy groceries", position: 0),
            TodoItem(title: "Read a chapter", position: 1),
            TodoItem(title: "Go for a walk", position: 2),
        ]
    }
}
