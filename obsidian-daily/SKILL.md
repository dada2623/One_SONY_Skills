---
name: obsidian-daily
description: Manage Obsidian Daily Notes via the official Obsidian CLI. Create and open daily notes, append journal entries with short mood and event tags, tasks, links and timestamped logs, read past notes by date, and search vault content. Handles relative dates like "yesterday", "last Friday", "3 days ago". Use when the user asks to write, read, or search their Obsidian daily notes or journal from the command line. Requires Obsidian 1.12.7+ with Command line interface enabled in Settings → General.
---

# Obsidian Daily Notes

Create, append to, read, and search Obsidian daily notes with the official `obsidian` CLI.

## Setup

Requires Obsidian 1.12.7+ with **Command line interface** enabled (Settings → General). The app must be running; if it is not, the first command launches it.

**Never run `obsidian` in a sandbox — from the very first command.** The CLI connects to the running app over a local connection; a restricted sandbox crashes the app (SIGABRT, exit 134). Always run it unsandboxed: if the environment restricts commands, request approval/exemption before executing, and do not attempt a sandboxed run first.

Verify:

```bash
obsidian version
obsidian vaults
```

**Default vault: `Obsidian`.** This skill always targets the `Obsidian` vault (path `/Users/hu/Library/CloudStorage/OneDrive-个人/应用/Obsidian`). Never rely on the current working directory or the most recently focused vault — those can silently redirect writes to the wrong vault (e.g. `耗材管理`).

Every command below passes `vault="Obsidian"` as the first parameter. Only use a different vault when the user explicitly asks for it:

```bash
obsidian vault="Obsidian" daily
```

### Daily Notes Location

All daily notes live in the `diaries/` folder of the **Obsidian** vault (configured in the vault's Daily notes settings). Today's note resolves to:

`/Users/hu/Library/CloudStorage/OneDrive-个人/应用/Obsidian/diaries/2026-08-06.md`

Verify:

```bash
obsidian vault="Obsidian" daily:path   # → diaries/2026-08-06.md
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
obsidian vault="Obsidian" daily
```

Opens today's daily note in Obsidian, creating it if it doesn't exist. Folder, date format, and template come from the vault's Daily notes settings.

### Append Entry to Today's Note

```bash
obsidian vault="Obsidian" daily:append content="ENTRY_TEXT"
```

Appends on a new line by default. Use `inline` to append without a newline, `open` to open the file after appending.

`daily:append` targets today's note. Whether it auto-creates a missing note has not been verified; if the note is missing, create it first (see below) and verify the write with `daily:read`.

Get today's note path (useful for scripts):

```bash
obsidian vault="Obsidian" daily:path
```

### Append to a Specific Date Note

`append` only works on files that **already exist**. On a missing file it exits 0 with no output and creates nothing — do not rely on the exit code.

```bash
obsidian vault="Obsidian" append path="diaries/2026-08-06.md" content="ENTRY_TEXT"
```

Create a missing date note first, then append:

```bash
obsidian vault="Obsidian" create path="diaries/2026-08-06.md" content="- FIRST_ENTRY"
obsidian vault="Obsidian" append path="diaries/2026-08-06.md" content="- SECOND_ENTRY"
```

### Update an Existing Note

The CLI has no in-place edit command. To change an existing note (e.g. fix a mood tag), read its full content first, edit it, then rewrite the whole file with `overwrite`:

```bash
obsidian vault="Obsidian" read path="diaries/2026-08-05.md"
obsidian vault="Obsidian" create path="diaries/2026-08-05.md" overwrite content="<FULL_EDITED_CONTENT>"
```

### Read Notes

Today:

```bash
obsidian vault="Obsidian" daily:read
```

Specific date:

```bash
obsidian vault="Obsidian" read path="diaries/2025-01-10.md"
```

Relative date (yesterday):

```bash
obsidian vault="Obsidian" read path="diaries/$(date -d yesterday +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d).md"
```

### Search Content

```bash
obsidian vault="Obsidian" search query="TERM"
obsidian vault="Obsidian" search:context query="TERM"   # grep-style output with line context
```

### Interactive Browse

```bash
obsidian vault="Obsidian"
```

Opens the TUI with autocomplete and fuzzy navigation.

### Specific Vault

Every command in this skill already passes `vault="Obsidian"` (see Setup). Keep it unless the user explicitly names a different vault:

```bash
obsidian vault="Obsidian" daily
obsidian vault="Obsidian" read path="diaries/2025-01-10.md"
```

## Use Cases

**Journal entry:**

```bash
obsidian vault="Obsidian" daily:append content="- Went to the doctor #情绪/平静"
```

**Task:**

```bash
obsidian vault="Obsidian" daily:append content="- [ ] Buy groceries"
```

**Link:**

```bash
obsidian vault="Obsidian" daily:append content="- https://github.com/anthropics/skills"
```

**Timestamped log:**

```bash
obsidian vault="Obsidian" daily:append content="- $(date +%H:%M) This is a log line"
```

**Read last Friday:**

```bash
obsidian vault="Obsidian" read path="diaries/$(date -d 'last friday' +%Y-%m-%d 2>/dev/null || date -v-friday +%Y-%m-%d).md"
```

**Search for "meeting":**

```bash
obsidian vault="Obsidian" search query="meeting"
```

## Tags

Every diary entry carries a few short tags for retrieval: one mood tag plus 1–3 event tags, appended inline at the end of the entry line.

**Reuse existing tags.** Check the vault before choosing:

```bash
obsidian vault="Obsidian" tags counts sort=count
```

**Mood tag (1 per entry, required).** The vault currently has no mood tags; use this minimal set (create only these):

- `#情绪/平静`
- `#情绪/开心`
- `#情绪/焦虑`
- `#情绪/疲惫`
- `#情绪/低落`
- `#情绪/烦躁`

**Event tags (1–3 per entry, reuse existing).** Examples already in the vault: `#开会` `#上班` `#学习` `#书籍` `#编程` `#论文` `#视频` `#播客` `#写作` `#消费` `#新闻` `#英文` `#发言稿` `#答辩`. If no existing tag fits an event, create one short new tag only when necessary.

**Example:**

```bash
obsidian vault="Obsidian" daily:append content="- 和团队开周会，确定 Q3 目标 #开会 #情绪/平静"
```

## Notes

- The app must be running; the CLI connects to the running Obsidian instance and launches it automatically if closed.
- **Never run `obsidian` in a sandbox.** A restricted sandbox crashes the app (SIGABRT, exit 134). Always run commands unsandboxed from the first call — do not try the sandbox first (see Setup).
- **Exit code 0 does not mean success.** `append` on a missing file and `read` on a missing file both exit 0 while doing nothing or printing an error. Judge success by the output and verify every write by reading the file back.
- If `obsidian version` warns the installer is out of date, download the latest installer from https://obsidian.md/download for full CLI support.
- If a note lands in the wrong vault, the `vault="Obsidian"` parameter was omitted — every write must include it.
- Use `\n` for newlines and `\t` for tabs in `content=` values.
- Use `--copy` on any command to copy output to the clipboard; use `silent` to prevent files from opening.
