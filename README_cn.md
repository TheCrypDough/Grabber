<div align="center">
  <img src="apps/web/public/icon.svg" alt="Grabber Logo" width="120" />
  <h1>Grabber</h1>
  <p><strong>End copy paste time waste.</strong><br/>在任何 AI 对话场景一键抓取完整上下文。</p>
  <p>
    <a href="https://github.com/TheCrypDough/Grabber">GitHub</a>
    ·
    <a href="#快速开始">快速开始</a>
    ·
    <a href="CHEATSHEET.md">Cheatsheet</a>
    ·
    <a href="AGENTS.md">Agent 指南</a>
    ·
    <a href="#命令总览">命令总览</a>
    ·
    <a href="#cliide-与-agent-工作流">CLI/IDE/Agent 工作流</a>
  </p>
</div>

---

## Grabber 是什么

Grabber 是一个开源对话抓取工具，把 AI 对话导出为结构化 Markdown，便于：

- 自己长期归档
- 多模型/多工具上下文迁移
- Agent 自动化 ingestion / retrieval / handoff

它包含两层能力：

1. 浏览器扩展层
- 在聊天页面一键复制或保存完整会话
- 自动携带 source/date/url/title 等 metadata

2. 系统级脚本层
- `grabber save` / `grabber autosave`
- `grabber ingest` / `grabber find` / `grabber summary` / `grabber code`

## 核心能力

- 一键复制完整会话
- 一键保存 `.md`
- 多格式导出（full / user-only / code-only / compact）
- 快捷键（`Alt+Shift+C` / `Alt+Shift+S`）
- 会话文件名带 metadata（时间/来源/上下文）
- 非浏览器会话（CLI/IDE）可统一归档
- Agent 可脚本化检索与生成上下文摘要

## 快速开始

### 1. 构建扩展

```bash
./scripts/install-global-commands.sh
grabber build
```

如果终端提示找不到 `grabber`，请把 `~/.local/bin` 加到 `PATH`。

### 2. Chrome 加载

1. 打开 `chrome://extensions`
2. 开启 `Developer mode`
3. 点击 `Load unpacked`
4. 选择：
`/home/thecrypdough/Github Repositories/Grabber/apps/browser-extension/dist/chrome-mv3`

### 3. 页面内使用

- 点击复制图标：复制会话
- 点击下载图标：保存会话
- 右键图标：选择导出格式
- 扩展弹窗：`Copy Current Conversation` / `Save Current Conversation (.md)`

## 命令总览

基础命令：

- `grabber` 或 `grabber build`
- `grabber dev`
- `grabber path`
- `grabber update`
- `grabber clean`
- `grabber help`

归档命令：

- `grabber save`
- `grabber save "context override"`
- `grabber autosave start|stop|status|restart`

跨来源/检索/再加工：

- `grabber ingest --source claude-code --title "auth fix" --input ./session.md`
- `grabber find --source gemini --latest 10`
- `grabber find --source gemini --include-derived --latest 20`
- `grabber summary --file ~/convos/<file>.md`
- `grabber code --file ~/convos/<file>.md`
- `grabber capture --source claude-code --title \"debug run\" -- claude`

兼容别名仍可用：

- `ctxport`
- `ctxport-save`
- `ctxport-autosave`

## 文件命名规则

保存后的文件名：

`YYYYMMDD-HHMMSS_source@host_context.md`

示例：

`20260219-132000_chatgpt@chatgpt-com_lambda-agent-memory-ingest-strategy.md`

## 平台覆盖（2026-02-19）

API-first 适配器：

- ChatGPT
- Claude
- Gemini
- DeepSeek
- Grok
- GitHub Issues/PR

通用 Web 最佳努力适配器：

- AI Studio
- Perplexity
- Kimi
- Genspark
- Poe
- Le Chat
- Copilot
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
- localhost/127.0.0.1 agent chat UI

## CLI/IDE 与 Agent 工作流

### CLI 工具（Claude Code / Codex / OpenCode）

1. 导出或保存会话文本到文件
2. 归档：

```bash
grabber ingest --source claude-code --title "lambda deploy issue" --input ./claude-session.md
grabber capture --source claude-code --title "lambda deploy issue" -- claude
```

3. 检索：

```bash
grabber find --source claude-code --latest 5
grabber find --contains "oauth refresh token" --date 2026-02-19
```

### IDE 聊天（Cursor / 各类扩展）

1. 把聊天导出/复制到文本文件
2. 归档：

```bash
grabber ingest --source cursor --title "feature planning" --input ./cursor-chat.txt
```

3. 产出可复用文件：

```bash
grabber summary --file ~/convos/<saved-file>.md
grabber code --file ~/convos/<saved-file>.md
```

### Agent 自动化建议

1. 每次 Agent run 结束后自动执行 `grabber ingest`
2. 需要历史上下文时先执行 `grabber find`
3. 交接时生成 `grabber summary`
4. 需要代码片段时生成 `grabber code`

这样同一套归档规范即可覆盖：浏览器对话、CLI 会话、IDE 会话、Agent workflow。

## 开发

要求：

- Node.js >= 22
- pnpm >= 10

```bash
pnpm install
pnpm build:ext
pnpm test
```

## 许可证

MIT
