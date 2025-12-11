import SwiftUI

struct SyncStatusView: View {
    @ObservedObject var viewModel: NoteViewModel

    var body: some View {
        HStack(spacing: 8) {
            statusIndicator

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            if let lastUpdated = viewModel.lastUpdated {
                Text(lastUpdated, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    @ViewBuilder
    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
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
    VStack(spacing: 20) {
        SyncStatusView(viewModel: NoteViewModel())
    }
    .padding()
}
