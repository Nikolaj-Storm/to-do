# GlassTodos — Setup Guide

A minimalist macOS to-do list widget with a soft "liquid glass" aesthetic.
Manage tasks directly from your desktop widget, or open the companion app for
drag-and-drop reordering and title editing.

---

## Quick Start (under 20 minutes)

### 1. Create the Xcode project

1. Open Xcode -> **File -> New -> Project**.
2. Choose **macOS -> App**. Click Next.
3. Set:
   - **Product Name:** `GlassTodos`
   - **Organization Identifier:** `com.yourname` (or your own)
   - **Interface:** SwiftUI
   - **Language:** Swift
4. Choose a location and click Create.
5. Delete the auto-generated `ContentView.swift` from the project navigator
   (move to trash).

### 2. Add the source files to the main app target

Drag these folders/files into the Xcode project navigator under the
`GlassTodos` group. Make sure **"Copy items if needed"** is checked and the
target **GlassTodos** is selected:

```
GlassTodos/
  App/
    GlassTodosApp.swift      (replace the auto-generated one)
    ContentView.swift
    GlassTodos.entitlements
    Assets.xcassets/
  Shared/
    TodoItem.swift
    TodoStore.swift
    ToggleTodoIntent.swift
    AddTodoIntent.swift
    DeleteTodoIntent.swift
    ClearDoneIntent.swift
    OpenAppIntent.swift
```

### 3. Add the Widget Extension target

1. **File -> New -> Target**.
2. Choose **macOS -> Widget Extension**. Click Next.
3. Set:
   - **Product Name:** `GlassTodosWidget`
   - **Include Configuration App Intent:** unchecked (we provide our own)
4. Click Finish. Xcode creates a `GlassTodosWidget` group.
5. **Delete** all auto-generated `.swift` files inside that group.
6. Drag in `GlassTodosWidget/GlassTodosWidget.swift` from this repo.
7. Also add the **Shared/** files to this target:
   - Select each file in Shared/ -> File Inspector -> check
     **GlassTodosWidgetExtension** under Target Membership.

### 4. Configure App Groups

Both targets need the same App Group so they can share UserDefaults data.

1. Select the **GlassTodos** target -> Signing & Capabilities -> **+ Capability**
   -> **App Groups** -> add `group.com.yourname.GlassTodos`.
2. Select the **GlassTodosWidgetExtension** target -> same steps -> add the
   **same** group identifier.
3. If you change the identifier, also update `TodoStore.appGroupID` in
   `TodoStore.swift`.

### 5. Set entitlements

- For the **GlassTodos** target, set the entitlements file to
  `GlassTodos/App/GlassTodos.entitlements`.
- For the **GlassTodosWidgetExtension** target, set it to
  `GlassTodosWidget/GlassTodosWidgetExtension.entitlements`.

(Or let Xcode generate them when you add App Groups -- just make sure the group
ID matches.)

### 6. Set deployment target

Set both targets to **macOS 14.0** (Sonoma) or later.

### 7. Build & Run

1. Select the **GlassTodos** scheme and press Cmd+R. The companion app opens.
2. Right-click your desktop -> **Edit Widgets** -> search "Glass Todos".
3. **Choose your widget size:**
   - **Small** — compact, shows 3 tasks
   - **Medium** — shows 5 tasks, wider layout
   - **Large** — shows 10 tasks, tall
   - **Extra Large** — macOS-only, biggest possible, 16 tasks in two columns
4. You can add **multiple widgets** of different sizes simultaneously!
5. Use the widget: tap checkmarks, tap "+", tap "x" to delete, or tap
   "Edit in app" to reorder and rename.

---

## Widget Sizes

| Size        | Tasks | Layout     | Best for                        |
|-------------|-------|------------|---------------------------------|
| Small       | 3     | Single col | Quick glance at top priorities  |
| Medium      | 5     | Single col | Daily task overview              |
| Large       | 10    | Single col | Full daily list                  |
| Extra Large | 16    | Two cols   | Power users, lots of tasks       |

**Note:** Widget sizes are fixed by macOS. You cannot freely resize them,
but you can pick the size that works best and place multiple widgets if needed.

---

## Widget Features

- **Tap checkmark** — toggle task done/not done
- **Tap "+"** — add a new task (titled "New task")
- **Tap "x"** — delete a task (medium/large/XL only)
- **"Clear done"** — remove all completed tasks at once
- **"Edit in app"** — open the main app for reordering and renaming
- **Pending count badge** — shows how many tasks are left

---

## Customization

### Colors
- **Widget palette:** edit the `GlassPalette` struct in
  `GlassTodosWidget.swift` (accent, row fills, background gradient).
- **App accent:** edit `accent` in `ContentView.swift`.

### Max visible tasks
- In `GlassTodosWidget.swift`, find `maxItems` and change the numbers
  (defaults: 3 small, 5 medium, 10 large, 16 extra large).

### App Group ID
- Change `TodoStore.appGroupID` in `TodoStore.swift`.
- Update both `.entitlements` files to match.
- Update the App Groups capability in Xcode for both targets.

---

## Architecture

```
+------------------------------------------+
|             Shared Code                  |
| TodoItem . TodoStore . App Intents       |
| (linked to both targets)                 |
+----------+--------------+---------------+
           |              |
   +-------v------+ +-----v--------------+
   | GlassTodos   | | GlassTodosWidget   |
   | (main app)   | | (widget extension) |
   |              | |                    |
   | ContentView  | | 4 sizes: S/M/L/XL |
   | + DnD reorder| | + Toggle, Add,    |
   | + Edit titles| |   Delete, Clear   |
   | + Delete     | |   via App Intents |
   +--------------+ +--------------------+
           |              |
           +------+-------+
                  |
        UserDefaults (App Group)
```

---

## Known WidgetKit Limitations

- **No drag-and-drop in widgets.** WidgetKit renders views as archived
  snapshots -- it does not support gesture recognizers or continuous
  interactions. Reorder tasks in the main app instead; the widget picks up
  the new order on the next timeline refresh or after any interactive button
  press.
- **No inline text editing in widgets.** New tasks are added with the default
  title "New task". Double-click a task title in the main app to rename it.
- **Fixed widget sizes.** macOS does not allow free-form widget resizing.
  Use Extra Large for the biggest possible widget, or place multiple widgets.
