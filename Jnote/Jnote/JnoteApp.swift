import SwiftUI

@main
struct JnoteApp: App {
    @StateObject private var viewModel = NoteViewModel()

    var body: some Scene {
        #if os(macOS)
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
        } label: {
            Label("Jnote", systemImage: "note.text")
        }
        .menuBarExtraStyle(.window)
        #else
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
        #endif
    }
}
