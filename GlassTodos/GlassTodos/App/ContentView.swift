import SwiftUI
import UniformTypeIdentifiers

// MARK: - Main App Content View
// Provides full editing: reorder via drag‑and‑drop, rename, delete.
// The widget reflects changes because both share the same TodoStore.

struct ContentView: View {

    @State private var items: [TodoItem] = TodoStore.load()
    @State private var editingID: UUID? = nil
    @State private var draggedItem: TodoItem? = nil

    // ── Tweak accent / pastel color here ──
    private let accentColor = Color(red: 0.55, green: 0.48, blue: 0.78) // soft lilac

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.3)
            taskList
        }
        .background(.ultraThinMaterial)
        .onAppear { items = TodoStore.load() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Tasks")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.8))
            Spacer()
            Button(action: addItem) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Task List (drag‑and‑drop reordering)

    private var taskList: some View {
        List {
            ForEach(items) { item in
                taskRow(item)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                    // Drag source
                    .onDrag {
                        draggedItem = item
                        return NSItemProvider(object: item.id.uuidString as NSString)
                    }
                    // Drop target
                    .onDrop(of: [.text], delegate: ReorderDropDelegate(
                        item: item,
                        items: $items,
                        draggedItem: $draggedItem,
                        onReorder: persist
                    ))
            }
            .onDelete(perform: deleteItems)
            .onMove(perform: moveItems)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Single Task Row

    private func taskRow(_ item: TodoItem) -> some View {
        HStack(spacing: 10) {
            // Checkmark toggle
            Button {
                toggleDone(item)
            } label: {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isDone ? accentColor : .secondary.opacity(0.5))
            }
            .buttonStyle(.plain)

            // Editable title
            if editingID == item.id {
                TextField("Task name", text: binding(for: item).title, onCommit: {
                    editingID = nil
                    persist()
                })
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .medium))
            } else {
                Text(item.title)
                    .font(.system(size: 14, weight: .medium))
                    .strikethrough(item.isDone)
                    .opacity(item.isDone ? 0.45 : 0.85)
                    .onTapGesture(count: 2) { editingID = item.id }
            }
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        )
    }

    // MARK: - Actions

    private func toggleDone(_ item: TodoItem) {
        guard let idx = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[idx].isDone.toggle()
        persist()
    }

    private func addItem() {
        let maxPos = items.map(\.position).max() ?? -1
        items.append(TodoItem(title: "New task", position: maxPos + 1))
        persist()
    }

    private func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        reindexAndPersist()
    }

    private func moveItems(from src: IndexSet, to dst: Int) {
        items.move(fromOffsets: src, toOffset: dst)
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

// MARK: - Drag‑and‑Drop Delegate

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
