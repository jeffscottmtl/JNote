import SwiftUI

#if os(macOS)
struct MenuBarView: View {
    @ObservedObject var viewModel: NoteViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            headerView

            Divider()

            ToolbarView(viewModel: viewModel)

            Divider()

            RichTextEditor(
                text: $viewModel.content,
                selectedRange: $viewModel.selectedRange
            )
            .frame(minWidth: 400, minHeight: 300)

            Divider()

            footerView
        }
        .frame(width: 450, height: 450)
        .task {
            await viewModel.loadNote()
        }
    }

    private var headerView: some View {
        HStack {
            Text("Jnote")
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            Button(action: {
                Task {
                    await viewModel.forceSyncNow()
                }
            }) {
                Image(systemName: viewModel.isSyncing ? "arrow.triangle.2.circlepath" : "icloud.and.arrow.up")
                    .symbolEffect(.rotate, isActive: viewModel.isSyncing)
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.isSyncing)

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var footerView: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            if let lastUpdated = viewModel.lastUpdated {
                Text("Updated ")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                +
                Text(lastUpdated, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var statusColor: Color {
        if viewModel.isSyncing {
            return .orange
        } else if viewModel.hasError {
            return .red
        } else if viewModel.isConnected {
            return .green
        } else {
            return .gray
        }
    }

    private var statusText: String {
        if viewModel.isSyncing {
            return "Syncing..."
        } else if viewModel.hasError {
            return "Sync error"
        } else if viewModel.isConnected {
            return "Synced"
        } else {
            return "Offline"
        }
    }
}

#Preview {
    MenuBarView(viewModel: NoteViewModel())
}
#endif
