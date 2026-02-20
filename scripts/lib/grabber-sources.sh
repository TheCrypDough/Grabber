#!/usr/bin/env bash

# Shared source registry used by scripts and docs.
# Format: id|category|description

grabber_source_rows() {
  cat <<'EOF'
chatgpt|web|OpenAI ChatGPT web app
claude|web|Anthropic Claude web app
gemini|web|Google Gemini web app
deepseek|web|DeepSeek chat web app
grok|web|xAI Grok web app
github|web|GitHub Issues and Pull Requests
aistudio|web|Google AI Studio
perplexity|web|Perplexity chat
kimi|web|Moonshot Kimi
genspark|web|Genspark chat
poe|web|Poe chat
mistral-chat|web|Mistral Le Chat
copilot|web|Microsoft Copilot web chat
qwen|web|Qwen chat web app
meta-ai|web|Meta AI chat
pi-ai|web|Pi chat
you-chat|web|You.com chat
duck-ai|web|Duck.ai
groq-chat|web|Groq chat UI
character-ai|web|Character.AI
huggingchat|web|HuggingChat
notebooklm|web|Google NotebookLM
openrouter-chat|web|OpenRouter chat
phind|web|Phind assistant
blackbox|web|Blackbox AI chat
codex-cloud|web|Codex cloud pages on chatgpt.com/codex
local-agent-chat|web|Localhost web chat fallback
claude-code|cli|Claude Code CLI sessions
codex-cli|cli|OpenAI Codex CLI sessions
opencode|cli|OpenCode CLI sessions
aider|cli|Aider terminal sessions
cursor|ide|Cursor IDE chat
antigravity|ide|Antigravity IDE chat
vscode-chat|ide|VS Code chat extensions
windsurf|ide|Windsurf editor chat
zed-assistant|ide|Zed assistant/chat
jetbrains-ai|ide|JetBrains AI Assistant chat
continue-dev|ide|Continue.dev IDE chat
cody|ide|Sourcegraph Cody chats
roo-code|ide|Roo Code IDE extension chats
agent-zero|agent|Agent Zero runs and chats
openclaw|agent|OpenClaw runs and chats
autogen|agent|AutoGen workflows
crewai|agent|CrewAI workflows
langgraph|agent|LangGraph agent workflows
EOF
}

grabber_source_ids() {
  grabber_source_rows | awk -F'|' 'NF >= 1 && $1 != "" { print $1 }'
}

grabber_source_categories() {
  grabber_source_rows | awk -F'|' 'NF >= 2 && $2 != "" { print $2 }' | sort -u
}
