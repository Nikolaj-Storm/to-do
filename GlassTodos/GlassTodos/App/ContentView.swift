import SwiftUI
import UniformTypeIdentifiers

// MARK: - Main App Content View
// Full editing: reorder via drag-and-drop, rename titles, delete tasks.
// The widget reflects all changes because both share the same TodoStore.

struct ContentView: View {

    @State private var items: [TodoItem] = TodoStore.load()
    @State private var editingID: UUID? = nil
    @State private var draggedItem: TodoItem? = nil
    @State private var hoveringID: UUID? = nil
    @State private var newTaskTitle: String = ""
    @FocusState private var isAddFieldFocused: Bool

    // ── Tweak accent / pastel color here ──
    private let accent = Color(red: 0.50, green: 0.42, blue: 0.80)

    var body: some View {
        VStack(spacing: 0) {
            header
            addBar
            Divider().opacity(0.15).padding(.horizontal, 16)
            taskList
            statusBar
        }
        .background(
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                LinearGradient(
                    colors: [
                        Color(red: 0.93, green: 0.90, blue: 1.00).opacity(0.3),
                        Color(red: 0.87, green: 0.93, blue: 1.00).opacity(0.2),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .onAppear { items = TodoStore.load() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Glass Todos")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.85))
                Text(dateString)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary.opacity(0.6))
            }
            Spacer()
            if !items.isEmpty {
                let pending = items.filter { !$0.isDone }.count
                Text("\(pending) left")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(accent.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule(style: .continuous).fill(accent.opacity(0.08))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date())
    }

    // MARK: - Add Task Bar

    private var addBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(accent.opacity(0.7))

            TextField("Add a task...", text: $newTaskTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .focused($isAddFieldFocused)
                .onSubmit { addTaskFromField() }

            if !newTaskTitle.isEmpty {
                Button {
                    addTaskFromField()
                } label: {
                    Text("Add")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(
                            Capsule(style: .continuous).fill(accent.opacity(0.85))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: - Task List (drag-and-drop reordering)

    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(items) { item in
                    taskRow(item)
                        .onDrag {
                            draggedItem = item
                            return NSItemProvider(object: item.id.uuidString as NSString)
                        }
                        .onDrop(of: [.text], delegate: ReorderDropDelegate(
                            item: item,
                            items: $items,
                            draggedItem: $draggedItem,
                            onReorder: reindexAndPersist
                        ))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Single Task Row

    private func taskRow(_ item: TodoItem) -> some View {
        let isHovering = hoveringID == item.id
        let isEditing = editingID == item.id

        return HStack(spacing: 10) {
            // Checkmark toggle
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { toggleDone(item) }
            } label: {
                ZStack {
                    Circle()
                        .stroke(
                            item.isDone ? accent.opacity(0.7) : Color.secondary.opacity(0.25),
                            lineWidth: 1.5
                        )
                        .frame(width: 22, height: 22)

                    if item.isDone {
                        Circle()
                            .fill(accent.opacity(0.75))
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            // Editable title — double-click to edit
            if isEditing {
                TextField("Task name", text: binding(for: item).title, onCommit: {
                    editingID = nil
                    persist()
                })
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .medium, design: .rounded))
            } else {
                Text(item.title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .strikethrough(item.isDone, color: .primary.opacity(0.3))
                    .foregroundStyle(.primary.opacity(item.isDone ? 0.38 : 0.82))
                    .onTapGesture(count: 2) { editingID = item.id }
            }

            Spacer()

            // Delete button — visible on hover
            if isHovering || isEditing {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { deleteItem(item) }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary.opacity(0.5))
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.secondary.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isHovering
                      ? Color.white.opacity(0.15)
                      : (item.isDone ? Color.white.opacity(0.04) : Color.white.opacity(0.08)))
                .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
        )
        .onHover { hovering in
            hoveringID = hovering ? item.id : nil
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        let doneCount = items.filter(\.isDone).count
        return HStack {
            if doneCount > 0 {
                Button {
                    withAnimation(.easeOut(duration: 0.25)) {
                        items.removeAll { $0.isDone }
                        reindexAndPersist()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                        Text("Clear \(doneCount) done")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(.secondary.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            Spacer()
            Text("\(items.count) tasks")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary.opacity(0.4))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: - Actions

    private func addTaskFromField() {
        let title = newTaskTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        let maxPos = items.map(\.position).max() ?? -1
        withAnimation(.easeOut(duration: 0.2)) {
            items.append(TodoItem(title: title, position: maxPos + 1))
        }
        newTaskTitle = ""
        isAddFieldFocused = true
        persist()
    }

    private func toggleDone(_ item: TodoItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isDone.toggle()
        persist()
    }

    private func deleteItem(_ item: TodoItem) {
        items.removeAll { $0.id == item.id }
        reindexAndPersist()
    }

    // MARK: - Helpers

    private func binding(for item: TodoItem) -> Binding<TodoItem> {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else {
            fatalError("Item not found")
        }
        return $items[idx]
    }

    private func persist() {
        TodoStore.save(items)
    }

    private func reindexAndPersist() {
        for i in items.indices { items[i].position = i }
        persist()
    }
}

// MARK: - Drag-and-Drop Delegate

struct ReorderDropDelegate: DropDelegate {
    let item: TodoItem
    @Binding var items: [TodoItem]
    @Binding var draggedItem: TodoItem?
    var onReorder: () -> Void

    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        onReorder()
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let dragged = draggedItem,
              dragged.id != item.id,
              let from = items.firstIndex(where: { $0.id == dragged.id }),
              let to = items.firstIndex(where: { $0.id == item.id })
        else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            items.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
