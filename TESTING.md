# Grabber Testing Guide

This guide explains how to test Grabber yourself across:
- web extension flows
- CLI flows
- IDE transcript flows
- Agent Zero
- OpenClaw and OpenClaw-style forks

## 1) Preflight

From repo root:

```bash
cd "/home/thecrypdough/Github Repositories/Grabber"
./scripts/install-global-commands.sh
grabber help
```

Expected:
- `grabber` command exists
- commands include `ingest`, `find`, `summary`, `code`, `handoff`, `capture`, `sources`

## 2) Fast Automated Smoke Test

Run the self-test script:

```bash
./scripts/grabber-self-test.sh
```

Optional extension build during self-test:

```bash
./scripts/grabber-self-test.sh --with-extension-build
```

Expected:
- all checks pass
- `Self-test PASS` is printed
- `Report: /tmp/grabber-selftest-.../self-test-report.md` is printed
- generated artifacts are printed under a temporary test directory

Notes:
- quick profile uses a representative set (`claude-code`, `cursor`, `openclaw`) to validate each path type.
- full profile validates every source returned by `grabber sources --ids`.
- generated self-test artifacts are stored under the printed temp path:
  - Linux path example: `/tmp/grabber-selftest-xxxx/`
  - Windows access via WSL UNC: `\\wsl.localhost\Ubuntu\tmp\grabber-selftest-xxxx\`

Run full profile:

```bash
./scripts/grabber-self-test.sh --profile full --run-plugin-tests
```

If you want temp files auto-removed:

```bash
./scripts/grabber-self-test.sh --cleanup
```

## 3) Extension Build + Load Test

Build:

```bash
grabber build
grabber path
```

Load in Chrome:
1. Open `chrome://extensions`
2. Enable `Developer mode`
3. Click `Load unpacked`
4. Select path from `grabber path`

Expected:
- extension loads with no errors
- popup shows copy/save actions on supported pages

## 4) Web UI Functional Test (Per Platform)

### Common test procedure

For each platform:
1. Open a conversation with at least:
- 2 user turns
- 2 assistant turns
- 1 code block
2. Click Grabber save icon (or popup `Save Current Conversation (.md)`).
3. Confirm a `.md` file is created.
4. Validate frontmatter contains:
- `grabber: v2`
- `source`
- `url`
- `title`
- `date`
- `format`
5. Verify retrieval:
```bash
grabber find --source <source-id> --latest 3
grabber find --source <source-id> --latest 3 --json
```
6. Generate derived artifacts:
```bash
f=$(grabber find --source <source-id> --latest 1 --paths)
grabber summary --file "$f"
grabber code --file "$f"
grabber handoff --file "$f"
```

### Web platform matrix

Use this source mapping when checking files with `grabber find`.
Canonical list command:

```bash
grabber sources
grabber sources --category web
grabber sources --ids
```

- ChatGPT: `chatgpt`
- Claude: `claude`
- Gemini: `gemini`
- DeepSeek: `deepseek`
- Grok: `grok`
- GitHub Issues/PR: `github`
- AI Studio: `aistudio`
- Perplexity: `perplexity`
- Kimi: `kimi`
- Genspark: `genspark`
- Poe: `poe`
- Le Chat: `mistral-chat`
- Copilot: `copilot`
- Qwen Chat: `qwen`
- Meta AI: `meta-ai`
- Pi: `pi-ai`
- You.com: `you-chat`
- Duck.ai: `duck-ai`
- Groq Chat: `groq-chat`
- Character.AI: `character-ai`
- HuggingChat: `huggingchat`
- NotebookLM: `notebooklm`
- OpenRouter Chat: `openrouter-chat`
- Phind: `phind`
- Blackbox: `blackbox`
- Codex cloud pages: `codex-cloud`
- Local web UIs fallback: `local-agent-chat`

## 5) CLI Flow Test

### Ingest existing transcript file

```bash
cat > /tmp/grabber-cli-test.md <<'EOF'
## User
Need retry-safe deploy plan.

## Assistant
Use canary and rollback checkpoints.

```bash
kubectl rollout undo deployment/api
```
EOF

grabber ingest --source claude-code --title "deploy retries" --input /tmp/grabber-cli-test.md
grabber find --source claude-code --latest 1
```

### Ingest via stdin

```bash
cat /tmp/grabber-cli-test.md | grabber ingest --stdin --source codex-cli --title "stdin ingest"
grabber find --source codex-cli --latest 1
```

### Capture live CLI run automatically

```bash
grabber capture --source opencode --title "capture smoke" -- bash -lc 'echo opencode session test'
grabber find --source opencode --latest 1
```

## 6) IDE Transcript Flow Test

This applies to Cursor, VS Code chat extensions, Antigravity, and similar IDE chat panes.

1. Export/copy chat transcript into a local text file.
2. Ingest with stable source name.

Examples:

```bash
grabber ingest --source cursor --title "refactor planning" --input ./cursor-chat.txt
grabber ingest --source antigravity --title "agent workflow debug" --input ./antigravity-chat.txt
grabber ingest --source vscode-chat --title "design review" --input ./vscode-chat.txt
```

3. Validate retrieval:

```bash
grabber find --source cursor --latest 3
```

## 7) Agent Zero Test

### Web UI path

Expected local URL patterns:
- `http://localhost:50001/...`
- `http://127.0.0.1:50001/...`
- or paths containing `agent-zero` / `agent0` on localhost

Test:
1. Start Agent Zero web UI.
2. Open conversation page in browser.
3. Use Grabber save icon.
4. Verify:
```bash
grabber find --source agent-zero --latest 3
```

If source is not `agent-zero`, check fallback:
```bash
grabber find --source local-agent-chat --latest 5
```

### Non-browser path

```bash
grabber capture --source agent-zero --title "agent-zero cli run" -- <your-agent-zero-command>
```

## 8) OpenClaw and OpenClaw Fork Test

### Web UI path

Expected coverage includes:
- `localhost/127.0.0.1` common local ports (including `18789`, `3000`)
- domains matched in adapter list
- localhost URLs containing `openclaw`, `clawdbot`, or similar fork naming

Test:
1. Open OpenClaw (or fork) chat UI.
2. Save conversation via Grabber.
3. Verify:
```bash
grabber find --source openclaw --latest 5
```

If your fork does not map to `openclaw`, ingest manually:
```bash
grabber ingest --source openclaw-fork --title "fork test" --input ./fork-transcript.txt
```

## 9) Autosave Daemon Test

```bash
grabber autosave start
grabber autosave status
grabber autosave stop
```

Expected:
- start prints PID/log path
- status shows running
- stop terminates cleanly

## 10) Quality/Regression Suite

Run from repo root:

```bash
pnpm lint
pnpm test
pnpm typecheck:extension
pnpm build:extension
pnpm test:core-plugins
```

Or run one logged command:

```bash
grabber validate --full
grabber doctor --full --auto-fix
```

This writes timestamped logs and summaries under:
- `reports/runs/<timestamp>/`
- `reports/latest` (symlink to newest run)

## 11) Troubleshooting

`grabber: command not found`:
- run `./scripts/install-global-commands.sh`
- ensure `~/.local/bin` is in `PATH`

No file saved from browser:
- verify page URL is supported
- try popup save button
- scroll up to load full conversation before saving

No matches in `grabber find`:
- check source label spelling
- remove strict filters
- try `--include-derived`

CLI capture fails:
- test command alone first
- use explicit source + title
- inspect raw logs in `~/.local/state/grabber/raw`

Handoff generation fails:
- verify source file exists and is a `.md` bundle
- run `grabber summary --file <bundle>.md` to isolate parser issues
- run `grabber handoff --file <bundle>.md --json` for machine-readable output

Validation failed:
- run `grabber doctor --full --auto-fix`
- inspect `reports/latest/SUMMARY.md`
- inspect each failed check log under `reports/latest/*.log`

## 12) Package Namespace

Internal workspace package scopes use `@grabber/*`.  
User-facing commands and docs use Grabber-first commands (`grabber ...`).
