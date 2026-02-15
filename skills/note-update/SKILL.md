---
name: note-update
description: "Find and update related documents in Obsidian vault (~/My_note/) based on conversation content. Use when: (1) user wants to reflect conversation insights into existing notes, (2) user wants to update a specific vault document, (3) user wants to find and enrich related notes based on discussion. Invoke with /note-update or /note-update [keyword|topic]."
argument-hint: "[keyword|topic]"
---

# Note Update

Find and update related documents in the Obsidian vault based on conversation content.

## Setup (MANDATORY — do this BEFORE any other step)

Read `~/My_note/CLAUDE.md` — vault structure, naming conventions, git workflow.

**If the read fails, STOP and report the error. Do not proceed without vault context.**

## Workflow

### 1. Analyze Conversation

- If `$ARGUMENTS` provided → use as search keyword/topic
- If empty → extract key topics and keywords from the entire conversation

### 2. Search Related Documents

Search the vault (`~/My_note/`) for related documents.

**Search folders (priority order):**

| Priority | Folder | Content |
|----------|--------|---------|
| 1 | `30.Expertise/` | Permanent notes, documents, resources |
| 2 | `10.Initiative/` | Projects |
| 3 | `40.Action/` | Active work |
| 4 | `20.Diary/` | Diary, meeting notes |
| 5 | `00.Inbox/` | Temporary notes |

**Excluded:** `90.Settings/`

**Search methods:**
- Filename matching (Glob)
- Frontmatter `tags`, `topics`, `domain` matching (Grep)
- Body keyword matching (Grep)

### 3. Present Candidates

Show search results to the user. Example:

```
Related documents found:

1. 30.Expertise/32.Permenent notes/DocA.md
   - topics: [related-topic]
   - relevance: high (3 keyword matches)

2. 10.Initiative/ProjectB/README.md
   - relevance: medium (1 keyword match)

Which document(s) to update?
```

**Do NOT modify any file until the user selects one.**

### 4. Update Document

After user selects a document:

- Preserve existing document structure and tone
- Update frontmatter `modified` to current datetime
- Integrate new content naturally into existing sections
- Add relevant wikilinks (`[[...]]`) if applicable

### 5. Confirm Changes

Show before/after diff to the user and get final approval before saving.

### 6. Git Sync (Optional)

Ask the user whether to push changes:

```bash
cd ~/My_note && git add . && git commit -m "Update: document-name" && git push origin master
```

## Constraints

- **Never modify a document without user confirmation** — always: present candidates → user selects → show diff → user approves
- Follow the existing frontmatter format of each document
- Do NOT use Templater syntax (`<% ... %>`) — insert actual values directly
- Write updates in the same language as the existing document
