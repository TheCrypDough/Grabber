<div align="center">
  <img src="apps/web/public/icon.svg" alt="Grabber Logo" width="120" />
  <h1>Grabber</h1>
  <p><strong>End copy paste time waste.</strong><br/>Use it anywhere you talk with AI.</p>
  <p>
    <a href="https://github.com/TheCrypDough/Grabber">GitHub</a>
    ·
    <a href="#quick-start">Quick Start</a>
    ·
    <a href="#how-it-works">How It Works</a>
    ·
    <a href="#platform-coverage-feb-19-2026">Coverage</a>
  </p>
</div>

---

## What Grabber Is

Grabber is an open-source tool for exporting AI conversations into clean, structured Markdown.

It combines two layers:

1. Browser extension layer
- One-click copy or save from supported AI chat pages.
- Structured output with frontmatter metadata for ingestion pipelines and agent context transfer.

2. Companion automation layer
- `grabber save` and `grabber autosave` commands for local archive workflows.
- Useful for agentic pipelines and clipboard-driven automation.

The goal is simple: preserve full conversations quickly, consistently, and in a format humans and agents can both use.

## Why This Exists

Manual conversation transfer is slow and fragile:

- raw copy often includes formatting junk
- code blocks can break
- context can be truncated or lost
- metadata (source/date/url) is usually missing

Grabber solves that by producing machine- and human-friendly Markdown bundles in one step.

## Core Features

- One-click copy full conversation
- One-click save full conversation to `.md`
- Right-click format menu (`full`, `user-only`, `code-only`, `compact`)
- Keyboard shortcuts for copy/save
- Sidebar list copy on supported platforms
- Setup UI for save behavior (prompt each save vs fast save)
- Metadata-rich filenames for archives
- Agent-friendly clipboard and autosave workflows

## How It Works

1. Grabber detects supported conversation pages via platform adapters.
2. It extracts message content into a universal `ContentBundle`.
3. It serializes the bundle into Markdown with metadata frontmatter.
4. You either:
- copy to clipboard, or
- save to disk as `.md`

Output frontmatter example:

```yaml
---
ctxport: v2
source: chatgpt
url: https://chatgpt.com/c/abc123
title: "Lambda agent routing strategy"
date: 2026-02-19T13:20:00Z
nodes: 24
format: full
---
```

## Quick Start

### 1. Build

```bash
grabber build
```

### 2. Load In Chrome

1. Open `chrome://extensions`
2. Enable `Developer mode`
3. Click `Load unpacked`
4. Select:
`/home/thecrypdough/Github Repositories/Grabber/apps/browser-extension/dist/chrome-mv3`

### 3. First-Time Save Setup

After install, Grabber opens the setup page where users choose:

- Save mode:
  - `Save directly (fast, no prompt)`
  - `Ask where to save every time`
- Download subfolder (relative to browser Downloads), for example:
  - `convos`
  - `convos/ai`

### 4. Use It

On any supported conversation page:

- click clipboard icon to copy full convo
- click download icon to save full convo
- right-click either icon to choose export format

Popup actions:

- `Copy Current Conversation`
- `Save Current Conversation (.md)`

Shortcuts:

- `Alt+Shift+C` copy current
- `Alt+Shift+S` save current

## Command Reference

Primary commands:

- `grabber` or `grabber build`
- `grabber dev`
- `grabber path`
- `grabber update`
- `grabber clean`
- `grabber help`

Archive/automation commands:

- `grabber save`
- `grabber save "context override"`
- `grabber autosave start`
- `grabber autosave stop`
- `grabber autosave status`
- `grabber autosave restart`

Compatibility aliases are still available:

- `ctxport`
- `ctxport-save`
- `ctxport-autosave`

## Archive Naming

Saved filenames are short but context-rich:

`YYYYMMDD-HHMMSS_source@host_context.md`

Example:

`20260219-132000_chatgpt@chatgpt-com_lambda-agent-memory-ingest-strategy.md`

Field mapping:

- timestamp from frontmatter `date` (UTC fallback if unavailable)
- source from `source`
- host from frontmatter `url`
- context from `title` or manual override

If a filename already exists, Grabber appends a suffix (`_02`, `_03`, ...).

## Platform Coverage (Feb 19, 2026)

### API-first adapters

- ChatGPT
- Claude
- Gemini
- DeepSeek
- Grok
- GitHub Issues/PR

### Universal best-effort web adapters

- Google AI Studio
- Perplexity
- Kimi
- Genspark
- Poe
- Mistral Le Chat
- Microsoft Copilot
- Qwen Chat
- Meta AI
- Pi
- You.com
- Duck.ai
- Groq Chat
- Character.AI
- HuggingChat
- NotebookLM
- OpenRouter Chat
- Phind
- Blackbox
- Codex Cloud pages on `chatgpt.com/codex`
- localhost/127.0.0.1 web agent chat UIs

## Extension Model vs Non-Browser Conversations

Grabber is still extension-first.

- For web-based chat UIs: use one-click copy/save directly in browser.
- For terminal-only conversations (`codex` CLI, `claude code`, `opencode` in pure terminal):
  use transcript/log/clipboard workflow + `grabber save`.

This hybrid model is intentional: browser-native ease for users, scriptable tooling for agents.

## Security & Privacy

- Local-first behavior
- No required account
- No cloud upload required for core export flows
- Uses browser permissions needed for extraction + save/download behavior

See `SECURITY.md` for policy and reporting.

## Repository Layout

```text
Grabber/
  apps/
    browser-extension/      # Chrome extension
    web/                    # Docs/website app
  packages/
    core-plugins/           # Platform adapters
    core-markdown/          # Serializer + formatting
    core-schema/            # Shared schema/types
    shared-ui/              # Shared UI components
  scripts/
    grabber-save.sh         # Archive save helper
    grabber-autosave.sh     # Clipboard autosave daemon
```

## Development

Requirements:

- Node.js >= 22
- pnpm >= 10

Install:

```bash
pnpm install
```

Build extension only:

```bash
pnpm build:ext
```

Typecheck:

```bash
pnpm --filter @ctxport/core-plugins typecheck
pnpm --filter @ctxport/extension typecheck
```

Run all tests:

```bash
pnpm test
```

## Operational Notes

- For fastest user experience, keep browser extension loaded and just click Reload after new builds.
- For deterministic archives, use `grabber save` in ingestion pipelines.
- For unattended local capture workflows, run `grabber autosave start`.

## Roadmap Direction

Near-term:

- improve per-site reliability on universal adapters
- strengthen non-browser transcript import paths
- streamline batch export workflows

Long-term:

- richer agent-native ingestion/export APIs
- optional multi-conversation packaging
- stronger cross-tool context portability standards

---

## License

MIT
