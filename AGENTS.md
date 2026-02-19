# AGENTS.md - Grabber Agent Operating Guide

This file defines how autonomous agents should use Grabber for conversation capture, retrieval, and handoff.

## Purpose

Use Grabber to normalize chat history from browser, CLI, and IDE tools into one archive format so agents can:
- recover prior context
- extract code artifacts
- generate handoff summaries
- continue work without manual copy/paste

## Canonical Paths

- Repo root:
`/home/thecrypdough/Github Repositories/Grabber`
- Archive folder:
`/home/thecrypdough/convos`
- Raw capture logs:
`~/.local/state/grabber/raw`

## Required Command Surface

Agents should call these commands only:

- `grabber save`
- `grabber autosave start|stop|status|restart`
- `grabber ingest ...`
- `grabber capture ... -- <command>`
- `grabber find ...`
- `grabber summary --file <bundle.md>`
- `grabber code --file <bundle.md>`

## Source Label Standard

Always provide a stable `--source` label for predictable retrieval.

Recommended source names:
- Browser: `chatgpt`, `claude`, `gemini`, `grok`, `perplexity`, `aistudio`, `kimi`, `genspark`
- CLI: `claude-code`, `codex-cli`, `opencode`
- IDE: `cursor`, `antigravity`, `vscode-chat`
- Agent frameworks: `agent-zero`, `openclaw`

Do not invent random spellings per run. Keep exact values.

## Ingestion Modes

### Mode A: Existing transcript file

Use when a transcript/log already exists.

```bash
grabber ingest \
  --source claude-code \
  --title "lambda deploy debugging" \
  --input ./session.md
```

### Mode B: Piped transcript

Use when transcript text is produced by another command.

```bash
cat ./session.txt | grabber ingest --stdin --source codex-cli --title "repo cleanup"
```

### Mode C: Live command capture

Use to run a CLI agent and archive automatically.

```bash
grabber capture --source claude-code --title "hotfix run" -- claude
grabber capture --source codex-cli --title "migration run" -- codex
```

## Retrieval Strategy

Always narrow results progressively:

1. Source + time:
```bash
grabber find --source claude-code --latest 20
```

2. Add context keyword:
```bash
grabber find --source claude-code --context "blank project" --latest 20
```

3. Add body text constraint:
```bash
grabber find --contains "oauth refresh token" --date 2026-02-19 --latest 10
```

4. For direct machine use, request paths:
```bash
grabber find --source claude-code --latest 1 --paths
```

By default, `grabber find` excludes derived files (`.summary.md`, `.code.md`).
Use `--include-derived` only when needed.

## Artifact Generation

### Summary artifact

```bash
grabber summary --file /home/thecrypdough/convos/<bundle>.md
```

Output:
- `/home/thecrypdough/convos/<bundle>.summary.md`

Use for:
- next-agent handoff context
- project memory snapshots
- lightweight briefing

### Code artifact

```bash
grabber code --file /home/thecrypdough/convos/<bundle>.md
```

Output:
- `/home/thecrypdough/convos/<bundle>.code.md`

Use for:
- extracting reusable snippets
- fast implementation handoff

## Agentic Workflow Templates

### Template: End-of-run archive

1. Capture or ingest transcript
2. Generate summary
3. Emit summary path to workflow state

Example:
```bash
grabber capture --source codex-cli --title "billing retry patch" -- codex
f="$(grabber find --source codex-cli --context billing-retry-patch --latest 1 --paths)"
grabber summary --file "$f"
echo "${f%.md}.summary.md"
```

### Template: Resume prior task

1. Locate previous convo
2. Generate summary + code
3. Feed both files into next agent prompt/context

```bash
f="$(grabber find --source claude-code --context blank --latest 1 --paths)"
grabber summary --file "$f"
grabber code --file "$f"
```

## Agent Zero / OpenClaw Guidance

Browser extension URL matching includes explicit support for:
- Agent Zero local defaults (including `localhost:50001`)
- OpenClaw local defaults (including `localhost:18789`)
- `localhost`, `127.0.0.1`, and `0.0.0.0` local stacks

If the framework runs outside browser (pure terminal/daemon):
- do not rely on extension
- use `grabber capture` or `grabber ingest`

## File Naming and Metadata

Bundle filenames:
- `YYYYMMDD-HHMMSS_source@host_context.md`

Context quality rules:
- keep short but meaningful
- include task intent (e.g., `lambda-deploy-debug`, `oauth-refresh-fix`)
- avoid vague context (`test`, `misc`, `tmp`)

## Reliability Rules

Agents should always:

1. Check command availability:
```bash
grabber help
```

2. Verify output file exists after ingest/capture.

3. On failure, retry with explicit `--title` and `--context`.

4. Never overwrite archive files manually; Grabber handles collision suffixing.

5. Prefer `--paths` when passing results to downstream automation.

## Security and Data Handling

- Archive may contain sensitive conversation content.
- Do not upload bundle files externally unless explicitly approved.
- Keep processing local by default.
- Redact secrets before sharing `.summary.md` or `.code.md`.

## Maintenance

After updating repo:

```bash
cd "/home/thecrypdough/Github Repositories/Grabber"
./scripts/install-global-commands.sh
grabber update
```

Health checks:

```bash
pnpm lint
pnpm test
pnpm build:ext
```
