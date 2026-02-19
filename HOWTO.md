# Grabber Setup and Usage

Project location:
- `/home/thecrypdough/Github Repositories/Grabber`

Default archive folder:
- Linux: `/home/thecrypdough/convos`
- Windows UNC: `\\wsl.localhost\Ubuntu\home\thecrypdough\convos`

## Quick Start (Builder)

Use these commands from any terminal directory:

- `grabber` or `grabber build` -> build extension
- `grabber path` -> print unpacked extension folder
- `grabber dev` -> run extension watch mode
- `grabber update` -> pull latest + reinstall + rebuild
- `grabber clean` -> remove old `dist/chrome-mv3` output
- `grabber help` -> command help

## Chrome Install / Reload

One-time install:
1. Open `chrome://extensions`
2. Enable **Developer mode**
3. Click **Load unpacked**
4. Select: `/home/thecrypdough/Github Repositories/Grabber/apps/browser-extension/dist/chrome-mv3`

After code changes:
1. Run `grabber build`
2. In `chrome://extensions`, click **Reload** on Grabber

## Zero-Terminal User Flow

Use Grabber directly in the browser (no terminal needed):

1. Open a supported AI conversation page.
2. Use in-page action buttons:
- Clipboard button: copy full conversation
- Download button: save full conversation as `.md`
- Right click either button: choose format (`full`, `user-only`, `code-only`, `compact`)
3. Or click the extension icon:
- `Copy Current Conversation`
- `Save Current Conversation (.md)`
4. Keyboard shortcuts:
- `Alt+Shift+C` -> copy current conversation
- `Alt+Shift+S` -> save current conversation

## Save Folder Setup UI

On first install, Grabber opens a setup page.

You can configure:
- **Save mode**
  - `Save directly (fast, no prompt)`
  - `Ask where to save every time`
- **Download subfolder**
  - Example: `convos` or `convos/ai`
  - This is relative to the browser Downloads folder

You can reopen setup anytime:
- Click the extension icon, then click **Save setup**
- Or open extension details in Chrome and click **Extension options**

## Agent / Automation Flows

Terminal companion commands (optional):

- `grabber save` -> save current clipboard bundle into archive folder
- `grabber save "context override"` -> force context text in filename
- `grabber autosave start` -> watch clipboard and auto-save Grabber bundles
- `grabber autosave stop`
- `grabber autosave status`
- `grabber autosave restart`

Compatibility aliases still work:
- `ctxport`, `ctxport-save`, `ctxport-autosave`

## Archive Naming

Archive filenames are short and metadata-rich:

- `YYYYMMDD-HHMMSS_source@host_context.md`

Example:
- `20260219-132000_chatgpt@chatgpt-com_lambda-agent-memory-ingest-strategy.md`

Field sources:
- `YYYYMMDD-HHMMSS`: frontmatter `date` (UTC), fallback = current UTC
- `source`: frontmatter `source`
- `host`: hostname parsed from frontmatter `url`
- `context`: frontmatter `title` or manual override

If a file exists, numeric suffixes are appended (`_02`, `_03`, ...).

## Coverage Summary

API-first adapters:
- ChatGPT
- Claude
- Gemini
- DeepSeek
- Grok
- GitHub Issues/PR

Universal best-effort web adapters include:
- AI Studio, Perplexity, Kimi, Genspark, Poe, Le Chat, Copilot, Qwen Chat
- Meta AI, Pi, You.com, Duck.ai, Groq Chat, Character.AI, HuggingChat
- NotebookLM, OpenRouter Chat, Phind, Blackbox
- Localhost/127.0.0.1 web agent chats

Note:
- Browser extension adapters work for web UIs.
- Pure terminal chats are handled through transcript/log + `grabber save` flow.
