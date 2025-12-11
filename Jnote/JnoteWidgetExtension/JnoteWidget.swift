import WidgetKit
import SwiftUI
import AppIntents

struct NoteEntry: TimelineEntry {
    let date: Date
    let noteContent: String
    let lastUpdated: Date?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> NoteEntry {
        NoteEntry(date: Date(), noteContent: "Your note will appear here...", lastUpdated: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (NoteEntry) -> Void) {
        let entry = loadNoteEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NoteEntry>) -> Void) {
        let entry = loadNoteEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadNoteEntry() -> NoteEntry {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let sharedDefaults = UserDefaults(suiteName: "group.com.jnote.shared"),
           let data = sharedDefaults.data(forKey: "savedNote"),
           let note = try? decoder.decode(WidgetNote.self, from: data) {
            return NoteEntry(
                date: Date(),
                noteContent: note.content,
                lastUpdated: note.updatedAt
            )
        }

        return NoteEntry(
            date: Date(),
            noteContent: "Tap to add a note...",
            lastUpdated: nil
        )
    }
}

struct WidgetNote: Codable {
    let id: UUID
    let userId: String
    let content: String
    let updatedAt: Date
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case content
        case updatedAt = "updated_at"
        case createdAt = "created_at"
    }
}

struct JnoteWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: NoteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "note.text")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Jnote")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Text(entry.noteContent.isEmpty ? "Tap to add a note..." : entry.noteContent)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(12)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct MediumWidgetView: View {
    let entry: NoteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "note.text")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Jnote")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                if let lastUpdated = entry.lastUpdated {
                    Text(lastUpdated, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Text(entry.noteContent.isEmpty ? "Tap to add a note..." : entry.noteContent)
                .font(.callout)
                .foregroundStyle(.primary)
                .lineLimit(4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(16)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct LargeWidgetView: View {
    let entry: NoteEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Jnote")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                if let lastUpdated = entry.lastUpdated {
                    Text(lastUpdated, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Divider()

            Text(entry.noteContent.isEmpty ? "Tap to add a note..." : entry.noteContent)
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(20)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct JnoteWidget: Widget {
    let kind: String = "JnoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            JnoteWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Jnote")
        .description("Quick access to your note.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    JnoteWidget()
} timeline: {
    NoteEntry(date: .now, noteContent: "This is a sample note with some content to preview.", lastUpdated: Date())
}

#Preview(as: .systemMedium) {
    JnoteWidget()
} timeline: {
    NoteEntry(date: .now, noteContent: "This is a sample note with some content to preview. It can be longer in the medium widget.", lastUpdated: Date())
}

#Preview(as: .systemLarge) {
    JnoteWidget()
} timeline: {
    NoteEntry(date: .now, noteContent: "This is a sample note with some content to preview. In the large widget, you can see much more of your note content without having to open the app.", lastUpdated: Date())
}
