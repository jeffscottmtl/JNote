import Foundation
import Combine
#if canImport(WidgetKit)
import WidgetKit
#endif

@MainActor
final class NoteSyncService: ObservableObject {
    @Published private(set) var note: Note?
    @Published private(set) var isSyncing: Bool = false
    @Published private(set) var lastSyncError: Error?
    @Published private(set) var isConnected: Bool = true

    private let userId: String
    private var debounceTask: Task<Void, Never>?
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private static let debounceInterval: TimeInterval = 1.5

    init(userId: String) {
        self.userId = userId

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    func loadNote() async {
        guard SupabaseConfig.isConfigured else {
            note = loadLocalNote() ?? Note(userId: userId)
            return
        }

        do {
            let notes = try await fetchNotes()
            if let existingNote = notes.first {
                self.note = existingNote
                saveLocalNote(existingNote)
            } else {
                let newNote = Note(userId: userId)
                try await createNote(newNote)
                self.note = newNote
                saveLocalNote(newNote)
            }
            lastSyncError = nil
            isConnected = true
        } catch {
            lastSyncError = error
            isConnected = false
            note = loadLocalNote() ?? Note(userId: userId)
        }
    }

    private func fetchNotes() async throws -> [Note] {
        guard let url = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/notes?user_id=eq.\(userId)&order=updated_at.desc&limit=1") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(SupabaseConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "x-user-id")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        return try decoder.decode([Note].self, from: data)
    }

    private func createNote(_ note: Note) async throws {
        guard let url = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/notes") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(SupabaseConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "x-user-id")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(note)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
    }

    func updateContent(_ content: String) {
        guard var currentNote = note else { return }
        currentNote.content = content
        currentNote.updatedAt = Date()
        self.note = currentNote

        saveLocalNote(currentNote)

        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .seconds(Self.debounceInterval))
            guard !Task.isCancelled else { return }
            await syncNote()
        }
    }

    func syncNote() async {
        guard let note = note, SupabaseConfig.isConfigured else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            try await upsertNote(note)
            lastSyncError = nil
            isConnected = true
        } catch {
            lastSyncError = error
            isConnected = false
        }
    }

    private func upsertNote(_ note: Note) async throws {
        guard let url = URL(string: "\(SupabaseConfig.supabaseURL)/rest/v1/notes?on_conflict=id") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(SupabaseConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(userId, forHTTPHeaderField: "x-user-id")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        request.httpBody = try encoder.encode(note)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
    }

    func forceSyncNow() async {
        debounceTask?.cancel()
        await syncNote()
    }

    private func loadLocalNote() -> Note? {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.jnote.shared"),
              let data = sharedDefaults.data(forKey: "savedNote") else {
            return nil
        }
        return try? decoder.decode(Note.self, from: data)
    }

    private func saveLocalNote(_ note: Note) {
        guard let data = try? encoder.encode(note) else { return }
        UserDefaults(suiteName: "group.com.jnote.shared")?.set(data, forKey: "savedNote")
        UserDefaults.standard.set(data, forKey: "savedNote")
        refreshWidgets()
    }

    private func refreshWidgets() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}

extension NoteSyncService {
    static func getUserId() -> String {
        let key = "com.jnote.userId"

        if let existingId = UserDefaults.standard.string(forKey: key) {
            return existingId
        }

        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }

    static func getSharedUserId() -> String {
        let appGroup = "group.com.jnote.shared"
        let key = "com.jnote.userId"

        if let sharedDefaults = UserDefaults(suiteName: appGroup),
           let existingId = sharedDefaults.string(forKey: key) {
            return existingId
        }

        let standardId = UserDefaults.standard.string(forKey: key) ?? UUID().uuidString

        if let sharedDefaults = UserDefaults(suiteName: appGroup) {
            sharedDefaults.set(standardId, forKey: key)
        }
        UserDefaults.standard.set(standardId, forKey: key)

        return standardId
    }
}
