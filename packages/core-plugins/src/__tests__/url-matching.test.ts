import { describe, expect, test, beforeEach, afterEach } from "vitest";
import {
  EXTENSION_HOST_PERMISSIONS,
  clearPlugins,
  findPlugin,
  registerBuiltinPlugins,
  universalWebChatPlugin,
} from "../index";

describe("plugin URL matching coverage", () => {
  beforeEach(() => {
    clearPlugins();
    registerBuiltinPlugins();
  });

  afterEach(() => {
    clearPlugins();
  });

  test.each([
    // Universal web providers
    "https://aistudio.google.com/app/prompts/new_chat",
    "https://www.perplexity.ai/search/what-is-rag",
    "https://kimi.com/chat/cn",
    "https://genspark.ai/chat/123",
    "https://poe.com/assistant",
    "https://chat.mistral.ai/chat/abc",
    "https://copilot.microsoft.com/chats/1",
    "https://chat.qwen.ai/",
    "https://meta.ai/",
    "https://pi.ai/talk",
    "https://you.com/search?q=agentic+workflows",
    "https://duck.ai/",
    "https://chat.groq.com/",
    "https://character.ai/chat",
    "https://huggingface.co/chat/",
    "https://notebooklm.google.com/",
    "https://openrouter.ai/chat",
    "https://phind.com/search",
    "https://blackbox.ai/",
    "https://chatgpt.com/codex",
    // Local/agentic stacks
    "http://localhost:50001/",
    "http://127.0.0.1:50001/chat",
    "http://localhost:18789/",
    "http://127.0.0.1:18789/chat",
    "https://openclaw.my/",
    "https://openclawdoc.com/",
    "http://0.0.0.0:3000/openclaw/chat",
    "http://localhost:11434/",
  ])("matches universal plugin for supported URL %s", (url) => {
    expect(universalWebChatPlugin.urls.match(url)).toBe(true);
    expect(findPlugin(url)?.id).toBe("universal-web-chat");
  });

  test("includes key host permissions for major and local stacks", () => {
    expect(EXTENSION_HOST_PERMISSIONS).toContain("https://aistudio.google.com/*");
    expect(EXTENSION_HOST_PERMISSIONS).toContain("https://perplexity.ai/*");
    expect(EXTENSION_HOST_PERMISSIONS).toContain("https://openrouter.ai/*");
    expect(EXTENSION_HOST_PERMISSIONS).toContain("http://localhost/*");
    expect(EXTENSION_HOST_PERMISSIONS).toContain("https://127.0.0.1/*");
    expect(EXTENSION_HOST_PERMISSIONS).toContain("http://0.0.0.0/*");
    expect(EXTENSION_HOST_PERMISSIONS).toContain("https://openclaw.my/*");
  });

  test("does not match unrelated website", () => {
    const url = "https://example.com/";
    expect(universalWebChatPlugin.urls.match(url)).toBe(false);
    expect(findPlugin(url)).toBeNull();
  });
});
