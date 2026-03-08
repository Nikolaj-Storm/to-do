import Foundation
import WidgetKit

// MARK: - Todo Store
// Persists items via App Group UserDefaults so both the app and widget share data.
//
// ┌──────────────────────────────────────────────────────────┐
// │  APP GROUP SETUP                                         │
// │                                                          │
// │  1. In Xcode, select each target (GlassTodos AND         │
// │     GlassTodosWidgetExtension).                          │
// │  2. Signing & Capabilities → + Capability → App Groups.  │
// │  3. Add: group.com.yourname.GlassTodos                   │
// │  4. Both targets must use the SAME group ID.              │
// │                                                          │
// │  To change the identifier, update `appGroupID` below.    │
// └──────────────────────────────────────────────────────────┘

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
            return sampleItems()
        }
        return items.sorted { $0.position < $1.position }
    }

    // MARK: - Write

    static func save(_ items: [TodoItem]) {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = try? JSONEncoder().encode(items)
        else { return }
        defaults.set(data, forKey: storeKey)
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

    static func clearDone() {
        var items = load()
        items.removeAll { $0.isDone }
        reindex(&items)
        save(items)
    }

    static func reindex(_ items: inout [TodoItem]) {
        items.sort { $0.position < $1.position }
        for i in items.indices { items[i].position = i }
    }

    // MARK: - Defaults

    private static func sampleItems() -> [TodoItem] {
        [
            TodoItem(title: "Plan the week ahead", position: 0),
            TodoItem(title: "Buy groceries", position: 1),
            TodoItem(title: "Read a chapter", position: 2),
            TodoItem(title: "Go for a walk", position: 3),
            TodoItem(title: "Water the plants", position: 4),
        ]
    }
}
