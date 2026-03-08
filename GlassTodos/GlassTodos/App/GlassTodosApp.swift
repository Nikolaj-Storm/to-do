import SwiftUI

// MARK: - App Entry Point

@main
struct GlassTodosApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 340, minHeight: 420)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 380, height: 520)
    }
}
