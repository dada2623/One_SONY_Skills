---
name: obsidian-daily
description: Manage Obsidian Daily Notes via the official Obsidian CLI. Create and open daily notes, append journal entries with short mood and event tags, tasks, links and timestamped logs, read past notes by date, and search vault content. Handles relative dates like "yesterday", "last Friday", "3 days ago". Use when the user asks to write, read, or search their Obsidian daily notes or journal from the command line. Requires Obsidian 1.12.7+ with Command line interface enabled in Settings → General.
---

# Obsidian Daily Notes

Create, append to, read, and search Obsidian daily notes with the official `obsidian` CLI.

## Setup

Requires Obsidian 1.12.7+ with **Command line interface** enabled (Settings → General). The app must be running; if it is not, the first command launches it.

Verify:

```bash
obsidian version
obsidian vaults
```

The CLI has no "default vault". It targets the vault of the current working directory, otherwise the most recently focused vault. Target a specific vault with `vault=<name>` as the first parameter:

```bash
obsidian vault="Work" daily
```

### Daily Notes Location

All daily notes live in the `diaries/` folder (configured in the vault's Daily notes settings). Verify:

```bash
obsidian daily:path   # → diaries/2026-08-06.md
```

## Date Handling

Get current date:

```bash
date +%Y-%m-%d
```

Cross-platform relative dates (GNU first, BSD fallback):

| Reference | Command |
|-----------|---------|
| Today | `date +%Y-%m-%d` |
| Yesterday | `date -d yesterday +%Y-%m-%d 2>/dev/null \|\| date -v-1d +%Y-%m-%d` |
| Last Friday | `date -d "last friday" +%Y-%m-%d 2>/dev/null \|\| date -v-friday +%Y-%m-%d` |
| 3 days ago | `date -d "3 days ago" +%Y-%m-%d 2>/dev/null \|\| date -v-3d +%Y-%m-%d` |
| Next Monday | `date -d "next monday" +%Y-%m-%d 2>/dev/null \|\| date -v+monday +%Y-%m-%d` |

## Commands

### Open/Create Today's Note

```bash
obsidian daily
```

Opens today's daily note in Obsidian, creating it if it doesn't exist. Folder, date format, and template come from the vault's Daily notes settings.

### Append Entry to Today's Note

```bash
obsidian daily:append content="ENTRY_TEXT"
```

Appends on a new line by default. Use `inline` to append without a newline, `open` to open the file after appending.

Get today's note path (useful for scripts):

```bash
obsidian daily:path
```

### Append to a Specific Date Note

```bash
obsidian append path="diaries/2026-08-06.md" content="ENTRY_TEXT"
```

### Read Notes

Today:

```bash
obsidian daily:read
```

Specific date:

```bash
obsidian read path="diaries/2025-01-10.md"
```

Relative date (yesterday):

```bash
obsidian read path="diaries/$(date -d yesterday +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d).md"
```

### Search Content

```bash
obsidian search query="TERM"
obsidian search:context query="TERM"   # grep-style output with line context
```

### Interactive Browse

```bash
obsidian
```

Opens the TUI with autocomplete and fuzzy navigation.

### Specific Vault

Add `vault="NAME"` as the first parameter to any command:

```bash
obsidian vault="Work" daily
obsidian vault="Work" read path="diaries/2025-01-10.md"
```

## Use Cases

**Journal entry:**

```bash
obsidian daily:append content="- Went to the doctor #情绪/平静"
```

**Task:**

```bash
obsidian daily:append content="- [ ] Buy groceries"
```

**Link:**

```bash
obsidian daily:append content="- https://github.com/anthropics/skills"
```

**Timestamped log:**

```bash
obsidian daily:append content="- $(date +%H:%M) This is a log line"
```

**Read last Friday:**

```bash
obsidian read path="diaries/$(date -d 'last friday' +%Y-%m-%d 2>/dev/null || date -v-friday +%Y-%m-%d).md"
```

**Search for "meeting":**

```bash
obsidian search query="meeting"
```

## Tags

Every diary entry carries a few short tags for retrieval: one mood tag plus 1–3 event tags, appended inline at the end of the entry line.

**Reuse existing tags.** Check the vault before choosing:

```bash
obsidian tags counts sort=count
```

**Mood tag (1 per entry, required).** The vault currently has no mood tags; use this minimal set (create only these):

- `#情绪/平静`
- `#情绪/开心`
- `#情绪/焦虑`
- `#情绪/疲惫`
- `#情绪/低落`

**Event tags (1–3 per entry, reuse existing).** Examples already in the vault: `#开会` `#上班` `#学习` `#书籍` `#编程` `#论文` `#视频` `#播客` `#写作` `#消费` `#新闻` `#英文` `#发言稿` `#答辩`. If no existing tag fits an event, create one short new tag only when necessary.

**Example:**

```bash
obsidian daily:append content="- 和团队开周会，确定 Q3 目标 #开会 #情绪/平静"
```

## Notes

- The app must be running; the CLI connects to the running Obsidian instance and launches it automatically if closed.
- If the CLI crashes (SIGABRT) or cannot connect, it is likely blocked by a restricted sandbox — run it unsandboxed, as it communicates with the app over a local connection.
- If `obsidian version` warns the installer is out of date, download the latest installer from https://obsidian.md/download for full CLI support.
- Use `\n` for newlines and `\t` for tabs in `content=` values.
- Use `--copy` on any command to copy output to the clipboard; use `silent` to prevent files from opening.
