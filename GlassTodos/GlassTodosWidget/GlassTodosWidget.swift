import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Entry

struct TodoEntry: TimelineEntry {
    let date: Date
    let items: [TodoItem]

    var pending: [TodoItem]   { items.filter { !$0.isDone } }
    var completed: [TodoItem] { items.filter { $0.isDone } }
}

// MARK: - Timeline Provider

struct TodoTimelineProvider: TimelineProvider {

    func placeholder(in context: Context) -> TodoEntry {
        TodoEntry(date: .now, items: TodoStore.load())
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoEntry) -> Void) {
        completion(TodoEntry(date: .now, items: TodoStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoEntry>) -> Void) {
        let entry = TodoEntry(date: .now, items: TodoStore.load())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Palette
// ── Tweak all colors here to adjust the "liquid glass" look ──

struct GlassPalette {
    // Accent for checkmarks, buttons, highlights
    static let accent       = Color(red: 0.50, green: 0.42, blue: 0.80)   // soft violet
    static let accentLight  = Color(red: 0.70, green: 0.64, blue: 0.92)   // lighter violet

    // Row background tints
    static let rowFill      = Color.white.opacity(0.12)
    static let rowDoneFill  = Color.white.opacity(0.06)

    // Background gradient
    static let bgTop        = Color(red: 0.93, green: 0.90, blue: 1.00).opacity(0.50)  // pale lilac
    static let bgBottom     = Color(red: 0.87, green: 0.93, blue: 1.00).opacity(0.40)  // pale blue

    static var bgGradient: LinearGradient {
        LinearGradient(colors: [bgTop, bgBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Widget View

struct GlassTodosWidgetView: View {

    var entry: TodoEntry
    @Environment(\.widgetFamily) var family

    // ── Maximum visible tasks per widget size ──
    // Tweak these numbers to show more or fewer rows.
    private var maxItems: Int {
        switch family {
        case .systemSmall:      return 3
        case .systemMedium:     return 5
        case .systemLarge:      return 10
        case .systemExtraLarge: return 16    // macOS-only, tallest widget
        default:                return 5
        }
    }

    // Use two columns for extraLarge to fill the wide space
    private var useColumns: Bool { family == .systemExtraLarge }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow
                .padding(.bottom, family == .systemSmall ? 4 : 8)

            if useColumns {
                twoColumnLayout
            } else {
                singleColumnLayout
            }

            Spacer(minLength: 0)
            footerRow
        }
        .padding(family == .systemSmall ? 10 : 16)
        .containerBackground(for: .widget) {
            ZStack {
                GlassPalette.bgGradient
                // Subtle inner glow for depth
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                    .padding(1)
            }
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(alignment: .center, spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                Text(headerTitle)
                    .font(.system(size: family == .systemSmall ? 13 : 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.80))

                if family != .systemSmall {
                    Text(dateString)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary.opacity(0.55))
                }
            }

            Spacer()

            // Task count badge
            if family != .systemSmall {
                Text("\(entry.pending.count) left")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(GlassPalette.accent.opacity(0.8))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(
                        Capsule(style: .continuous)
                            .fill(GlassPalette.accent.opacity(0.10))
                    )
            }

            // Add button
            Button(intent: AddTodoIntent()) {
                Image(systemName: "plus")
                    .font(.system(size: family == .systemSmall ? 12 : 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: family == .systemSmall ? 22 : 26, height: family == .systemSmall ? 22 : 26)
                    .background(
                        Circle()
                            .fill(GlassPalette.accent.opacity(0.85))
                            .shadow(color: GlassPalette.accent.opacity(0.3), radius: 4, y: 2)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var headerTitle: String {
        let cal = Calendar.current
        if cal.isDateInToday(entry.date) { return "Today" }
        if cal.isDateInTomorrow(entry.date) { return "Tomorrow" }
        return "Tasks"
    }

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: entry.date)
    }

    // MARK: - Single Column Layout (small / medium / large)

    private var singleColumnLayout: some View {
        let visible = Array(entry.items.prefix(maxItems))
        let remaining = entry.items.count - visible.count

        return VStack(alignment: .leading, spacing: family == .systemSmall ? 3 : 5) {
            ForEach(visible) { item in
                taskRow(item, compact: family == .systemSmall)
            }

            if remaining > 0 {
                Text("+\(remaining) more")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary.opacity(0.45))
                    .padding(.leading, 4)
                    .padding(.top, 2)
            }
        }
    }

    // MARK: - Two Column Layout (extraLarge)

    private var twoColumnLayout: some View {
        let visible = Array(entry.items.prefix(maxItems))
        let mid = (visible.count + 1) / 2
        let left = Array(visible.prefix(mid))
        let right = Array(visible.suffix(from: min(mid, visible.count)))
        let remaining = entry.items.count - visible.count

        return HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                ForEach(left) { item in
                    taskRow(item, compact: false)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 5) {
                ForEach(right) { item in
                    taskRow(item, compact: false)
                }
                if remaining > 0 {
                    Text("+\(remaining) more")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary.opacity(0.45))
                        .padding(.leading, 4)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Task Row

    private func taskRow(_ item: TodoItem, compact: Bool) -> some View {
        HStack(spacing: compact ? 6 : 8) {
            // Checkmark toggle
            Button(intent: ToggleTodoIntent(itemID: item.id.uuidString)) {
                ZStack {
                    Circle()
                        .stroke(
                            item.isDone ? GlassPalette.accent.opacity(0.7) : Color.secondary.opacity(0.25),
                            lineWidth: 1.5
                        )
                        .frame(width: compact ? 16 : 20, height: compact ? 16 : 20)

                    if item.isDone {
                        Circle()
                            .fill(GlassPalette.accent.opacity(0.75))
                            .frame(width: compact ? 16 : 20, height: compact ? 16 : 20)

                        Image(systemName: "checkmark")
                            .font(.system(size: compact ? 8 : 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            // Title
            Text(item.title)
                .font(.system(size: compact ? 11 : 13, weight: .medium, design: .rounded))
                .strikethrough(item.isDone, color: .primary.opacity(0.3))
                .foregroundStyle(.primary.opacity(item.isDone ? 0.35 : 0.80))
                .lineLimit(1)

            Spacer(minLength: 0)

            // Delete button (not on small widgets — no room)
            if !compact {
                Button(intent: DeleteTodoIntent(itemID: item.id.uuidString)) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.secondary.opacity(0.3))
                        .frame(width: 16, height: 16)
                        .background(
                            Circle().fill(Color.secondary.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, compact ? 4 : 6)
        .padding(.horizontal, compact ? 6 : 10)
        .background(
            RoundedRectangle(cornerRadius: compact ? 8 : 10, style: .continuous)
                .fill(item.isDone ? GlassPalette.rowDoneFill : GlassPalette.rowFill)
                .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        )
    }

    // MARK: - Footer
    // NOTE: True drag-and-drop reordering is NOT possible inside a WidgetKit
    // widget. WidgetKit views are archived snapshots and don't support gesture
    // recognizers or continuous interactions like dragging.
    //
    // Workaround: "Edit in app" opens the main app where you get full
    // drag-and-drop reordering. The widget picks up the new order immediately
    // when any interactive button is pressed.

    private var footerRow: some View {
        HStack(spacing: 12) {
            // Clear completed button (only if there are completed tasks)
            if !entry.completed.isEmpty && family != .systemSmall {
                Button(intent: ClearDoneIntent()) {
                    HStack(spacing: 3) {
                        Image(systemName: "trash")
                            .font(.system(size: 9))
                        Text("Clear done")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(.secondary.opacity(0.45))
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button(intent: OpenAppIntent()) {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 9))
                    if family != .systemSmall {
                        Text("Edit in app")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                    }
                }
                .foregroundStyle(.secondary.opacity(0.45))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 4)
    }
}

// MARK: - Widget Configuration
// We support all four macOS widget sizes.
// systemExtraLarge is macOS-only and gives the largest possible widget.
//
// To add the widget to your desktop:
// Right-click desktop -> Edit Widgets -> search "Glass Todos" -> choose a size.
// You can add MULTIPLE widgets of different sizes simultaneously.

struct GlassTodosWidget: Widget {
    let kind: String = "GlassTodosWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodoTimelineProvider()) { entry in
            GlassTodosWidgetView(entry: entry)
        }
        .configurationDisplayName("Glass Todos")
        .description("A minimalist to-do list for your desktop.")
        .supportedFamilies([
            .systemSmall,       // compact 3-task view
            .systemMedium,      // 5 tasks, wider
            .systemLarge,       // 10 tasks, tall
            .systemExtraLarge,  // macOS-only: biggest, 16 tasks in two columns
        ])
    }
}

// MARK: - Widget Bundle (entry point for the extension)

@main
struct GlassTodosWidgetBundle: WidgetBundle {
    var body: some Widget {
        GlassTodosWidget()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    GlassTodosWidget()
} timeline: {
    TodoEntry(date: .now, items: [
        TodoItem(title: "Buy groceries", position: 0),
        TodoItem(title: "Read a chapter", isDone: true, position: 1),
        TodoItem(title: "Go for a walk", position: 2),
    ])
}

#Preview("Medium", as: .systemMedium) {
    GlassTodosWidget()
} timeline: {
    TodoEntry(date: .now, items: [
        TodoItem(title: "Buy groceries", position: 0),
        TodoItem(title: "Read a chapter", isDone: true, position: 1),
        TodoItem(title: "Go for a walk", position: 2),
        TodoItem(title: "Water the plants", position: 3),
        TodoItem(title: "Write journal entry", position: 4),
    ])
}

#Preview("Large", as: .systemLarge) {
    GlassTodosWidget()
} timeline: {
    TodoEntry(date: .now, items: [
        TodoItem(title: "Plan the week", position: 0),
        TodoItem(title: "Buy groceries", position: 1),
        TodoItem(title: "Read a chapter", isDone: true, position: 2),
        TodoItem(title: "Go for a walk", position: 3),
        TodoItem(title: "Water the plants", position: 4),
        TodoItem(title: "Reply to emails", position: 5),
        TodoItem(title: "Cook dinner", position: 6),
        TodoItem(title: "Meditate", isDone: true, position: 7),
        TodoItem(title: "Sketch ideas", position: 8),
        TodoItem(title: "Tidy desk", position: 9),
    ])
}

#Preview("Extra Large", as: .systemExtraLarge) {
    GlassTodosWidget()
} timeline: {
    TodoEntry(date: .now, items: (0..<14).map { i in
        TodoItem(title: "Task \(i + 1)", isDone: i % 5 == 0, position: i)
    })
}
