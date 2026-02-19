# Grabber Cheatsheet (Human Users)

This is the shortest path to use Grabber effectively across browser chats, CLI chats, and IDE chats.

For full step-by-step validation by platform, see `TESTING.md`.

## 1) One-Time Setup

```bash
cd "/home/thecrypdough/Github Repositories/Grabber"
./scripts/install-global-commands.sh
grabber build
```

Chrome install:
1. Open `chrome://extensions`
2. Enable `Developer mode`
3. Click `Load unpacked`
4. Select:
`/home/thecrypdough/Github Repositories/Grabber/apps/browser-extension/dist/chrome-mv3`

## 2) Daily Browser Use (No Terminal)

On supported chat pages:
- Click clipboard icon: copy full conversation
- Click download icon: save full conversation
- Right-click icon: choose format (`full`, `user-only`, `code-only`, `compact`)

Popup:
- `Copy Current Conversation`
- `Save Current Conversation (.md)`

Shortcuts:
- `Alt+Shift+C` copy
- `Alt+Shift+S` save

## 3) Save Folder and Naming

Default archive:
- `/home/thecrypdough/convos`

Filename pattern:
- `YYYYMMDD-HHMMSS_source@host_context.md`

Example:
- `20260219-132000_chatgpt@chatgpt-com_lambda-agent-memory-ingest-strategy.md`

## 4) CLI Commands You Will Actually Use

General:
- `grabber help`
- `grabber path`
- `grabber update`
- `grabber self-test --profile full --run-plugin-tests`
- `grabber validate --full`

Archive:
- `grabber save`
- `grabber save "context override"`
- `grabber autosave start|stop|status|restart`

Import non-browser transcript:
- `grabber ingest --source claude-code --title "auth refactor" --input ./session.md`
- `cat session.txt | grabber ingest --stdin --source codex-cli --title "db fix"`

Run a CLI tool and auto-capture session:
- `grabber capture --source claude-code --title "lambda hotfix" -- claude`
- `grabber capture --source codex-cli --title "repo cleanup" -- codex`

Find old conversations:
- `grabber find --source claude-code --latest 10`
- `grabber find --contains "oauth refresh token" --date 2026-02-19`
- `grabber find --context "blank project" --latest 5 --paths`
- `grabber find --include-derived --latest 20`

Generate derived files:
- `grabber summary --file ~/convos/<file>.md`
- `grabber code --file ~/convos/<file>.md`

## 5) Real Scenarios

Scenario: "Find my Claude Code session from blank project"
```bash
grabber find --source claude-code --context "blank" --latest 20
```

Scenario: "I need code from that conversation"
```bash
grabber code --file /home/thecrypdough/convos/<exact-file>.md
```

Scenario: "I need summary context for another agent"
```bash
grabber summary --file /home/thecrypdough/convos/<exact-file>.md
```

Scenario: Cursor/IDE chat export
```bash
grabber ingest --source cursor --title "feature planning" --input ./cursor-chat.txt
```

## 6) Source Labels (Recommended)

Use consistent `--source` values:
- `chatgpt`, `claude`, `gemini`, `grok`, `perplexity`
- `claude-code`, `codex-cli`, `opencode`
- `cursor`, `antigravity`, `vscode-chat`
- `agent-zero`, `openclaw`

## 7) Agent Zero / OpenClaw Notes

Browser extension now includes explicit universal matching for:
- Agent Zero local defaults (`localhost/127.0.0.1:50001`)
- OpenClaw local defaults (`localhost/127.0.0.1:18789`, common local patterns)
- Local stacks on `0.0.0.0`

For CLI or non-browser flows, use:
- `grabber capture ...`
- or `grabber ingest ...`

## 8) Quick Health Checks

```bash
grabber help
grabber path
grabber self-test
grabber validate --quick
pnpm lint
pnpm test
pnpm build:extension
```

## 9) Compatibility Aliases

Legacy commands still work:
- `ctxport`
- `ctxport-save`
- `ctxport-autosave`
