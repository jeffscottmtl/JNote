import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: NoteViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ToolbarView(viewModel: viewModel)

                RichTextEditor(
                    text: $viewModel.content,
                    selectedRange: $viewModel.selectedRange
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider()

                SyncStatusView(viewModel: viewModel)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .navigationTitle("Jnote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        Task {
                            await viewModel.forceSyncNow()
                        }
                    }) {
                        Image(systemName: viewModel.isSyncing ? "arrow.triangle.2.circlepath" : "icloud.and.arrow.up")
                            .symbolEffect(.rotate, isActive: viewModel.isSyncing)
                    }
                    .disabled(viewModel.isSyncing)
                }
            }
        }
        .task {
            await viewModel.loadNote()
        }
    }
}

#Preview {
    ContentView(viewModel: NoteViewModel())
}
