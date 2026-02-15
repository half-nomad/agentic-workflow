---
name: note-new
description: "Create a new Obsidian note from conversation summary, or copy an existing file to Obsidian Inbox. Use when: (1) user wants to save conversation content as a note, (2) user wants to send a file to Obsidian Inbox, (3) user wants to organize a specific topic from the conversation into a note. Invoke with /note-new or /note-new [file_path|topic]."
argument-hint: "[file_path|topic]"
---

# Note New

Create a new Obsidian note from conversation summary or copy an existing file to the Inbox.

## Setup (MANDATORY — do this BEFORE any other step)

1. Read `~/My_note/CLAUDE.md` — vault structure, naming conventions, git workflow
2. List `~/My_note/90.Settings/92.Templates/` — available note templates

**If either read fails, STOP and report the error. Do not proceed without vault context.**

## Mode Decision

Determine mode from `$ARGUMENTS`:

**File path exists on disk?** → File Copy mode
**Text (topic) or empty?** → Note Create mode

## File Copy Mode

1. Copy the file to `~/My_note/00.Inbox/` (preserve original filename)
2. If same filename exists, ask user before overwriting
3. Verify the copy succeeded
4. Only allow text-based files (md, txt, json, etc.)

## Note Create Mode

### 1. Analyze Conversation

- If `$ARGUMENTS` is topic text → summarize around that topic
- If empty → summarize the entire conversation's key content

### 2. Select Template

Choose the best-matching template from `~/My_note/90.Settings/92.Templates/`:

| Content Type | Template | `type` value |
|-------------|----------|-------------|
| General knowledge, conversation summary | `Document template.md` | Document |
| External article/video/book summary | `Reference-note template.md` | reference-note |
| Zettelkasten atomic idea | `Card template.md` | Card |
| Study/reading notes | `Literature Note template.md` | Literature-note |
| Personal insight, permanent thought | `Permenent note template.md` | Permanent-note |
| Blog/social media draft | `Post-template.md` | Draft |
| Project kickoff | `New Project.md` | project-note |
| Quick draft | `Draft Note template.md` | Draft |

**Default**: `Document template.md` if unclear.

If the user specifies a template type (e.g., "card", "reference"), use that template.

### 3. Write Note

Read the selected template file to get the exact frontmatter fields and body structure, then:

1. **Copy all frontmatter fields** from the template exactly
2. **Replace Templater placeholders** with actual values:
   - `<% tp.file.creation_date("YYYY-MM-DD") %>` → today's date
   - `<% tp.file.title %>` → note title
   - `modified:` → current datetime (YYYY-MM-DD HH:mm)
3. **Fill available fields**: `tags`, `topics`, `domain`, `source: Claude Code conversation`
4. **Write body** following the template's callout structure, then append the summarized content

### 4. Determine Filename

- Clear topic → use topic as filename: `Topic.md`
- Unclear → ask the user

### 5. Save

- Location: `~/My_note/00.Inbox/`
- If same filename exists, ask user before overwriting
- Verify the file was saved

## Constraints

- Do NOT use Templater syntax (`<% ... %>`) — insert actual values directly
- Use today's date for `created`, current datetime for `modified`
- Write note body in the same language as the conversation (typically Korean)
