import SwiftUI
import Combine

@MainActor
final class NoteViewModel: ObservableObject {
    @Published var content: String = "" {
        didSet {
            guard !isApplyingRemoteUpdate else { return }
            if oldValue != content {
                syncService?.updateContent(content)
            }
        }
    }
    @Published var selectedRange: NSRange = NSRange(location: 0, length: 0)
    @Published private(set) var isSyncing: Bool = false
    @Published private(set) var isConnected: Bool = true
    @Published private(set) var hasError: Bool = false
    @Published private(set) var lastUpdated: Date?

    private var syncService: NoteSyncService?
    private var cancellables = Set<AnyCancellable>()
    private var isApplyingRemoteUpdate = false

    init() {
        setupSyncService()
    }

    private func setupSyncService() {
        let userId = NoteSyncService.getSharedUserId()
        syncService = NoteSyncService(userId: userId)

        syncService?.$note
            .receive(on: DispatchQueue.main)
            .sink { [weak self] note in
                guard let self, let note else { return }
                self.isApplyingRemoteUpdate = true
                if self.content != note.content {
                    self.content = note.content
                }
                self.lastUpdated = note.updatedAt
                self.isApplyingRemoteUpdate = false
            }
            .store(in: &cancellables)

        syncService?.$isSyncing
            .receive(on: DispatchQueue.main)
            .assign(to: &$isSyncing)

        syncService?.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &$isConnected)

        syncService?.$lastSyncError
            .receive(on: DispatchQueue.main)
            .map { $0 != nil }
            .assign(to: &$hasError)
    }

    func loadNote() async {
        await syncService?.loadNote()
    }

    func forceSyncNow() async {
        await syncService?.forceSyncNow()
    }

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            Task { [weak self] in
                await self?.syncService?.forceSyncNow()
            }
        case .background:
            Task { [weak self] in
                await self?.syncService?.forceSyncNow()
            }
        default:
            break
        }
    }

    func toggleBold() {
        applyFormatting(.bold)
    }

    func toggleItalic() {
        applyFormatting(.italic)
    }

    func toggleUnderline() {
        applyFormatting(.underline)
    }

    func toggleStrikethrough() {
        applyFormatting(.strikethrough)
    }

    func insertHeading() {
        insertPrefix("# ")
    }

    func toggleBulletList() {
        insertPrefix("- ")
    }

    func toggleNumberedList() {
        insertPrefix("1. ")
    }

    func toggleCode() {
        wrapSelection("`", "`")
    }

    private func applyFormatting(_ style: TextFormattingStyle) {
        guard selectedRange.length > 0 else { return }

        let prefix: String
        let suffix: String

        switch style {
        case .bold:
            prefix = "**"
            suffix = "**"
        case .italic:
            prefix = "_"
            suffix = "_"
        case .underline:
            prefix = "<u>"
            suffix = "</u>"
        case .strikethrough:
            prefix = "~~"
            suffix = "~~"
        }

        wrapSelection(prefix, suffix)
    }

    private func wrapSelection(_ prefix: String, _ suffix: String) {
        guard selectedRange.length > 0,
              let range = Range(selectedRange, in: content) else { return }

        let selectedText = String(content[range])
        let newText = prefix + selectedText + suffix

        content.replaceSubrange(range, with: newText)
    }

    private func insertPrefix(_ prefix: String) {
        guard let range = Range(selectedRange, in: content) else { return }

        let lineStart = content[..<range.lowerBound].lastIndex(of: "\n")
            .map { content.index(after: $0) }
            ?? content.startIndex

        content.insert(contentsOf: prefix, at: lineStart)
    }
}

enum TextFormattingStyle {
    case bold
    case italic
    case underline
    case strikethrough
}
