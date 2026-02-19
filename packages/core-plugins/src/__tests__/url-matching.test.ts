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
    "http://localhost:50001/",
    "http://127.0.0.1:50001/chat",
    "http://localhost:18789/",
    "http://127.0.0.1:18789/chat",
    "https://openclaw.my/",
    "https://openclawdoc.com/",
    "http://0.0.0.0:3000/openclaw/chat",
  ])("matches universal plugin for agentic chat URL %s", (url) => {
    expect(universalWebChatPlugin.urls.match(url)).toBe(true);
    expect(findPlugin(url)?.id).toBe("universal-web-chat");
  });

  test("includes key host permissions for local agent stacks", () => {
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
