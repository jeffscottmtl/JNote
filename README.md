# Jnote

A lightweight, universal Swift app that keeps a single rich-text note in sync across macOS, iOS, and iPadOS. Jnote lives in the macOS menu bar for quick access and ships with a configurable widget on mobile platforms so you can glance at or open your note instantly.

## Features
- **Menu bar first on macOS**: Click the menu bar icon to pop open a focused editor window with formatting controls and live sync status.
- **iOS and iPadOS ready**: Modern SwiftUI interface with navigation and toolbar controls that mirror the desktop experience.
- **Widget support**: The widget reads from the shared app group for fast display and links back into the app via the `jnote://open` deep link.
- **Automatic syncing**: Edits debounce for a moment, save to a shared app group for the widget, and push to Supabase when credentials are provided.
- **Rich text helpers**: Quick-format buttons for bold, italics, underline, strikethrough, headings, lists, and inline code.

## Configuration
1. Create a free Supabase project and a `notes` table matching the `Note` model fields (`id`, `user_id`, `content`, `updated_at`, `created_at`).
2. Add your Supabase URL and anon key to the Xcode build settings (or via an `.xcconfig`) so they flow into `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `Info.plist`.
3. Ensure the app group `group.com.jnote.shared` is enabled for both the app target and the widget extension so on-device storage stays in sync.

If Supabase credentials are omitted, Jnote still works fully offline using the shared app group storage.
