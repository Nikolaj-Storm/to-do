# GlassTodos — Setup Guide

A minimalist macOS to-do list widget with a soft "liquid glass" aesthetic.
Manage tasks directly from your desktop widget, or open the companion app for
drag-and-drop reordering and title editing.

---

## Quick Start (under 20 minutes)

### 1. Create the Xcode project

1. Open Xcode → **File → New → Project**.
2. Choose **macOS → App**. Click Next.
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
├── App/
│   ├── GlassTodosApp.swift      (replace the auto-generated one)
│   ├── ContentView.swift
│   ├── GlassTodos.entitlements
│   └── Assets.xcassets/
└── Shared/
    ├── TodoItem.swift
    ├── TodoStore.swift
    ├── ToggleTodoIntent.swift
    ├── AddTodoIntent.swift
    └── OpenAppIntent.swift
```

### 3. Add the Widget Extension target

1. **File → New → Target**.
2. Choose **macOS → Widget Extension**. Click Next.
3. Set:
   - **Product Name:** `GlassTodosWidget`
   - **Include Configuration App Intent:** unchecked (we provide our own)
4. Click Finish. Xcode creates a `GlassTodosWidget` group.
5. **Delete** all auto-generated `.swift` files inside that group.
6. Drag in `GlassTodosWidget/GlassTodosWidget.swift` from this repo.
7. Also add the **Shared/** files to this target:
   - Select each file in Shared/ → File Inspector → check
     **GlassTodosWidgetExtension** under Target Membership.

### 4. Configure App Groups

Both targets need the same App Group so they can share UserDefaults data.

1. Select the **GlassTodos** target → Signing & Capabilities → **+ Capability**
   → **App Groups** → add `group.com.yourname.GlassTodos`.
2. Select the **GlassTodosWidgetExtension** target → same steps → add the
   **same** group identifier.
3. If you change the identifier, also update `TodoStore.appGroupID` in
   `TodoStore.swift`.

### 5. Set entitlements

- For the **GlassTodos** target, set the entitlements file to
  `GlassTodos/App/GlassTodos.entitlements`.
- For the **GlassTodosWidgetExtension** target, set it to
  `GlassTodosWidget/GlassTodosWidgetExtension.entitlements`.

(Or let Xcode generate them when you add App Groups — just make sure the group
ID matches.)

### 6. Set deployment target

Set both targets to **macOS 14.0** (Sonoma) or later.

### 7. Build & Run

1. Select the **GlassTodos** scheme and press ⌘R. The companion app opens.
2. Right-click your desktop → **Edit Widgets** → search "Glass Todos" → add
   the medium or large widget.
3. Use the widget! Tap checkmarks, tap "+", and tap "Edit in app" to reorder.

---

## Customization

### Colors
- **Widget accent & gradient:** edit `accentColor` and `bgGradient` in
  `GlassTodosWidget.swift` (search for "Tweak pastel / accent colors here").
- **App accent:** edit `accentColor` in `ContentView.swift`.
- **Asset catalog accent:** edit `AccentColor.colorset/Contents.json`.

### Max visible tasks
- In `GlassTodosWidget.swift`, find `maxItems` and change the numbers
  (default: 5 for medium, 10 for large).

### App Group ID
- Change `TodoStore.appGroupID` in `TodoStore.swift`.
- Update both `.entitlements` files to match.
- Update the App Groups capability in Xcode for both targets.

---

## Architecture

```
┌──────────────────────────────────────────┐
│              Shared Code                 │
│  TodoItem · TodoStore · App Intents      │
│  (linked to both targets)                │
└──────────┬──────────────┬────────────────┘
           │              │
   ┌───────▼──────┐ ┌─────▼──────────────┐
   │  GlassTodos  │ │ GlassTodosWidget   │
   │  (main app)  │ │ (widget extension) │
   │              │ │                    │
   │ ContentView  │ │ GlassTodosWidget   │
   │ + DnD reorder│ │ + Interactive      │
   │ + Edit titles│ │   buttons via      │
   │ + Delete     │ │   App Intents      │
   └──────────────┘ └────────────────────┘
           │              │
           └──────┬───────┘
                  │
        UserDefaults (App Group)
```

---

## Known WidgetKit Limitations

- **No drag-and-drop in widgets.** WidgetKit renders views as archived
  snapshots — it does not support gesture recognizers or continuous
  interactions. Reorder tasks in the main app instead; the widget picks up
  the new order on the next timeline refresh or after any interactive button
  press.
- **No inline text editing in widgets.** New tasks are added with the default
  title "New task". Double-click a task title in the main app to rename it.
