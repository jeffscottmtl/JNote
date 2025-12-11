/*
  # Create notes table for Jnote app

  1. New Tables
    - `notes`
      - `id` (uuid, primary key) - Unique identifier for the note
      - `user_id` (text, not null) - Device/user identifier for syncing
      - `content` (text) - The rich text content stored as JSON
      - `updated_at` (timestamptz) - Last modification timestamp
      - `created_at` (timestamptz) - Creation timestamp

  2. Security
    - Enable RLS on `notes` table
    - Add policy for users to manage their own notes based on user_id
*/

CREATE TABLE IF NOT EXISTS notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id text NOT NULL,
  content text DEFAULT '',
  updated_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- Create index for faster lookups by user_id
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id);

-- Enable Row Level Security
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;

-- Policy: Users can select their own notes
CREATE POLICY "Users can view own notes"
  ON notes
  FOR SELECT
  TO anon
  USING (user_id = current_setting('request.headers', true)::json->>'x-user-id');

-- Policy: Users can insert their own notes
CREATE POLICY "Users can insert own notes"
  ON notes
  FOR INSERT
  TO anon
  WITH CHECK (user_id = current_setting('request.headers', true)::json->>'x-user-id');

-- Policy: Users can update their own notes
CREATE POLICY "Users can update own notes"
  ON notes
  FOR UPDATE
  TO anon
  USING (user_id = current_setting('request.headers', true)::json->>'x-user-id')
  WITH CHECK (user_id = current_setting('request.headers', true)::json->>'x-user-id');

-- Policy: Users can delete their own notes
CREATE POLICY "Users can delete own notes"
  ON notes
  FOR DELETE
  TO anon
  USING (user_id = current_setting('request.headers', true)::json->>'x-user-id');