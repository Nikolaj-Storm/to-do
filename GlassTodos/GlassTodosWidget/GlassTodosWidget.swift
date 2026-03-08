import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Entry

struct TodoEntry: TimelineEntry {
    let date: Date
    let items: [TodoItem]
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
        // Refresh every 30 minutes as a fallback; intents also trigger reloads.
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Widget View

struct GlassTodosWidgetView: View {

    var entry: TodoEntry
    @Environment(\.widgetFamily) var family

    // ── Maximum visible tasks per widget size ──
    // Tweak these numbers if you want more or fewer rows.
    private var maxItems: Int {
        switch family {
        case .systemLarge: return 10
        default:           return 5   // medium
        }
    }

    // ── Tweak pastel / accent colors here ──
    private let accentColor  = Color(red: 0.55, green: 0.48, blue: 0.78) // soft lilac
    private let bgGradient   = LinearGradient(
        colors: [
            Color(red: 0.92, green: 0.90, blue: 0.98).opacity(0.55),  // pale lilac
            Color(red: 0.88, green: 0.94, blue: 0.98).opacity(0.45),  // pale blue
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow
            Spacer(minLength: 4)
            taskRows
            Spacer(minLength: 0)
            footerRow
        }
        .padding(14)
        // "Liquid glass" background: blurred material + pastel gradient overlay.
        .containerBackground(for: .widget) {
            ZStack {
                Color.clear // required base layer
                bgGradient
            }
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text("Tasks")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.75))
            Spacer()
            // Interactive "+" button — triggers AddTodoIntent
            Button(intent: AddTodoIntent()) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(accentColor)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Task Rows

    private var taskRows: some View {
        let visible = Array(entry.items.prefix(maxItems))
        return VStack(alignment: .leading, spacing: 6) {
            ForEach(visible) { item in
                taskRow(item)
            }
        }
    }

    private func taskRow(_ item: TodoItem) -> some View {
        HStack(spacing: 8) {
            // Interactive checkmark toggle — triggers ToggleTodoIntent
            Button(intent: ToggleTodoIntent(itemID: item.id.uuidString)) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 15))
                    .foregroundStyle(item.isDone ? accentColor : .secondary.opacity(0.45))
            }
            .buttonStyle(.plain)

            Text(item.title)
                .font(.system(size: 13, weight: .medium))
                .strikethrough(item.isDone)
                .opacity(item.isDone ? 0.4 : 0.82)
                .lineLimit(1)
            Spacer()
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.5))
                .shadow(color: .black.opacity(0.03), radius: 1, y: 0.5)
        )
    }

    // MARK: - Footer
    // NOTE: True drag‑and‑drop reordering is NOT possible inside a WidgetKit
    // widget (as of macOS 15 / WidgetKit 2024). WidgetKit views are rendered
    // as archived snapshots — they don't support gesture recognizers or
    // continuous interactions like dragging.
    //
    // Workaround: tap "Edit in app" to open the main app, where full
    // drag‑and‑drop reordering is available. The widget will pick up
    // the new order on the next timeline refresh (or immediately when
    // you toggle / add via the widget).

    private var footerRow: some View {
        HStack {
            Spacer()
            Button(intent: OpenAppIntent()) {
                Label("Edit in app", systemImage: "pencil.circle")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Widget Configuration

struct GlassTodosWidget: Widget {
    let kind: String = "GlassTodosWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodoTimelineProvider()) { entry in
            GlassTodosWidgetView(entry: entry)
        }
        .configurationDisplayName("Glass Todos")
        .description("A minimalist to‑do list widget.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Widget Bundle (entry point for the extension)

@main
struct GlassTodosWidgetBundle: WidgetBundle {
    var body: some Widget {
        GlassTodosWidget()
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    GlassTodosWidget()
} timeline: {
    TodoEntry(date: .now, items: [
        TodoItem(title: "Buy groceries", position: 0),
        TodoItem(title: "Read a chapter", isDone: true, position: 1),
        TodoItem(title: "Go for a walk", position: 2),
    ])
}
