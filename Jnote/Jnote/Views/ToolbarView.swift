import SwiftUI

struct ToolbarView: View {
    @ObservedObject var viewModel: NoteViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                FormatButton(icon: "bold", action: viewModel.toggleBold)
                FormatButton(icon: "italic", action: viewModel.toggleItalic)
                FormatButton(icon: "underline", action: viewModel.toggleUnderline)
                FormatButton(icon: "strikethrough", action: viewModel.toggleStrikethrough)

                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, 4)

                FormatButton(icon: "text.badge.plus", action: viewModel.insertHeading)
                FormatButton(icon: "list.bullet", action: viewModel.toggleBulletList)
                FormatButton(icon: "list.number", action: viewModel.toggleNumberedList)

                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, 4)

                FormatButton(icon: "chevron.left.forwardslash.chevron.right", action: viewModel.toggleCode)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGray6))
    }
}

struct FormatButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemBackground))
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ToolbarView(viewModel: NoteViewModel())
}
