import type { ContentBundle } from "@ctxport/core-schema";
import { createAppError } from "@ctxport/core-schema";
import type { Plugin, PluginContext } from "../../types";
import { generateId } from "../../utils";

interface UniversalProvider {
  id: string;
  name: string;
  assistantName: string;
  hosts: string[];
  match: (url: string) => boolean;
  titleSelectors?: string[];
  userSelectors?: string[];
  assistantSelectors?: string[];
  messageSelectors?: string[];
}

interface RoleCandidate {
  role: "user" | "assistant";
  text: string;
  element: Element;
}

const BASE_TITLE_SELECTORS = [
  "h1",
  '[data-testid*="title"]',
  '[class*="title"]',
  '[class*="conversation-title"]',
  '[class*="thread-title"]',
  '[aria-label*="title"]',
];

const BASE_USER_SELECTORS = [
  '[data-message-author-role="user"]',
  '[data-role="user"]',
  '[data-testid*="user-message"]',
  '[data-testid*="userMessage"]',
  '[class*="user-message"]',
  '[class*="from-user"]',
  '[class*="human-message"]',
  '[class*="prompt"]',
];

const BASE_ASSISTANT_SELECTORS = [
  '[data-message-author-role="assistant"]',
  '[data-role="assistant"]',
  '[data-testid*="assistant-message"]',
  '[data-testid*="assistantMessage"]',
  '[class*="assistant-message"]',
  '[class*="from-assistant"]',
  '[class*="ai-message"]',
  '[class*="bot-message"]',
  '[class*="response"]',
];

const BASE_MESSAGE_SELECTORS = [
  '[data-message-author-role]',
  '[data-testid*="message"]',
  '[data-testid*="turn"]',
  '[class*="chat-message"]',
  '[class*="conversation-turn"]',
  '[class*="thread-message"]',
  '[class*="message-row"]',
  "article",
  '[role="article"]',
];

const CONVERSATION_ROOT_SELECTORS = [
  'main[role="main"]',
  "main",
  '[class*="conversation"]',
  '[class*="chat"]',
  '[class*="thread"]',
  '[data-testid*="conversation"]',
  '[data-testid*="chat"]',
];

const NOISE_PATTERNS = [
  /^copy$/i,
  /^copied$/i,
  /^share$/i,
  /^edit$/i,
  /^delete$/i,
  /^retry$/i,
  /^regenerate$/i,
  /^thinking$/i,
  /^tools$/i,
  /^new chat$/i,
  /^chat history$/i,
  /^sign in$/i,
  /^sign up$/i,
  /^continue$/i,
];

const UNIVERSAL_PROVIDERS: UniversalProvider[] = [
  {
    id: "aistudio",
    name: "Google AI Studio",
    assistantName: "AI Studio",
    hosts: ["https://aistudio.google.com/*"],
    match: (url) => /^https?:\/\/aistudio\.google\.com\//i.test(url),
  },
  {
    id: "perplexity",
    name: "Perplexity",
    assistantName: "Perplexity",
    hosts: ["https://perplexity.ai/*", "https://www.perplexity.ai/*"],
    match: (url) => /^https?:\/\/(?:www\.)?perplexity\.ai\//i.test(url),
  },
  {
    id: "kimi",
    name: "Kimi",
    assistantName: "Kimi",
    hosts: ["https://www.kimi.com/*", "https://kimi.com/*"],
    match: (url) => /^https?:\/\/(?:www\.)?kimi\.com\//i.test(url),
  },
  {
    id: "genspark",
    name: "Genspark",
    assistantName: "Genspark",
    hosts: ["https://www.genspark.ai/*", "https://genspark.ai/*"],
    match: (url) => /^https?:\/\/(?:www\.)?genspark\.ai\//i.test(url),
  },
  {
    id: "poe",
    name: "Poe",
    assistantName: "Poe",
    hosts: ["https://poe.com/*", "https://www.poe.com/*"],
    match: (url) => /^https?:\/\/(?:www\.)?poe\.com\//i.test(url),
  },
  {
    id: "mistral-chat",
    name: "Le Chat",
    assistantName: "Mistral",
    hosts: ["https://chat.mistral.ai/*"],
    match: (url) => /^https?:\/\/chat\.mistral\.ai\//i.test(url),
  },
  {
    id: "copilot",
    name: "Microsoft Copilot",
    assistantName: "Copilot",
    hosts: ["https://copilot.microsoft.com/*"],
    match: (url) => /^https?:\/\/copilot\.microsoft\.com\//i.test(url),
  },
  {
    id: "qwen",
    name: "Qwen Chat",
    assistantName: "Qwen",
    hosts: ["https://chat.qwen.ai/*"],
    match: (url) => /^https?:\/\/chat\.qwen\.ai\//i.test(url),
  },
  {
    id: "meta-ai",
    name: "Meta AI",
    assistantName: "Meta AI",
    hosts: ["https://meta.ai/*", "https://www.meta.ai/*"],
    match: (url) => /^https?:\/\/(?:www\.)?meta\.ai\//i.test(url),
  },
  {
    id: "pi-ai",
    name: "Pi",
    assistantName: "Pi",
    hosts: ["https://pi.ai/*", "https://www.pi.ai/*"],
    match: (url) => /^https?:\/\/(?:www\.)?pi\.ai\//i.test(url),
  },
  {
    id: "you-chat",
    name: "You.com",
    assistantName: "YouChat",
    hosts: ["https://you.com/*", "https://www.you.com/*"],
    match: (url) => /^https?:\/\/(?:www\.)?you\.com\//i.test(url),
  },
  {
    id: "duck-ai",
    name: "Duck.ai",
    assistantName: "Duck.ai",
    hosts: ["https://duck.ai/*"],
    match: (url) => /^https?:\/\/duck\.ai\//i.test(url),
  },
  {
    id: "groq-chat",
    name: "Groq Chat",
    assistantName: "Groq",
    hosts: ["https://chat.groq.com/*"],
    match: (url) => /^https?:\/\/chat\.groq\.com\//i.test(url),
  },
  {
    id: "character-ai",
    name: "Character.AI",
    assistantName: "Character",
    hosts: ["https://character.ai/*", "https://beta.character.ai/*"],
    match: (url) => /^https?:\/\/(?:beta\.)?character\.ai\//i.test(url),
  },
  {
    id: "huggingchat",
    name: "HuggingChat",
    assistantName: "HuggingChat",
    hosts: ["https://huggingface.co/chat/*"],
    match: (url) => /^https?:\/\/huggingface\.co\/chat\//i.test(url),
  },
  {
    id: "notebooklm",
    name: "NotebookLM",
    assistantName: "NotebookLM",
    hosts: ["https://notebooklm.google.com/*"],
    match: (url) => /^https?:\/\/notebooklm\.google\.com\//i.test(url),
  },
  {
    id: "openrouter-chat",
    name: "OpenRouter Chat",
    assistantName: "OpenRouter",
    hosts: ["https://openrouter.ai/chat/*", "https://openrouter.ai/*"],
    match: (url) => /^https?:\/\/openrouter\.ai\/(?:chat\/?|$)/i.test(url),
  },
  {
    id: "phind",
    name: "Phind",
    assistantName: "Phind",
    hosts: ["https://phind.com/*", "https://www.phind.com/*"],
    match: (url) => /^https?:\/\/(?:www\.)?phind\.com\//i.test(url),
  },
  {
    id: "blackbox",
    name: "Blackbox",
    assistantName: "Blackbox",
    hosts: ["https://blackbox.ai/*", "https://www.blackbox.ai/*"],
    match: (url) => /^https?:\/\/(?:www\.)?blackbox\.ai\//i.test(url),
  },
  {
    id: "codex-cloud",
    name: "Codex Cloud",
    assistantName: "Codex",
    hosts: ["https://chatgpt.com/*"],
    match: (url) => /^https?:\/\/chatgpt\.com\/codex(?:\/|$)/i.test(url),
    titleSelectors: ['[data-testid*="task-title"]', "h1"],
  },
  {
    id: "local-agent-chat",
    name: "Local Agent Chat",
    assistantName: "Agent",
    hosts: [
      "http://localhost/*",
      "https://localhost/*",
      "http://127.0.0.1/*",
      "https://127.0.0.1/*",
    ],
    match: (url) => /^https?:\/\/(?:localhost|127\.0\.0\.1)(?::\d+)?\//i.test(url),
    titleSelectors: ["h1", "title"],
  },
];

const UNIVERSAL_HOSTS = Array.from(
  new Set(UNIVERSAL_PROVIDERS.flatMap((provider) => provider.hosts)),
);

export const universalWebChatPlugin: Plugin = {
  id: "universal-web-chat",
  version: "1.0.0",
  name: "Universal Web Chat",

  urls: {
    hosts: UNIVERSAL_HOSTS,
    match: (url) => findProvider(url) != null,
  },

  async extract(ctx: PluginContext): Promise<ContentBundle> {
    const provider = findProvider(ctx.url);
    if (!provider) {
      throw createAppError("E-PARSE-001", "Unsupported chat URL");
    }

    const extraction = extractMessagesFromDom(ctx.document, provider);
    if (extraction.messages.length === 0) {
      throw createAppError(
        "E-PARSE-005",
        `No messages found for ${provider.name}. Try scrolling up to load conversation history first.`,
      );
    }

    const nodes: ContentBundle["nodes"] = extraction.messages.map(
      (message, index) => ({
        id: generateId(),
        participantId: message.role,
        content: message.text,
        order: index,
        type: "message",
      }),
    );

    return {
      id: generateId(),
      title: extraction.title,
      participants: [
        { id: "user", name: "User", role: "user" },
        {
          id: "assistant",
          name: provider.assistantName,
          role: "assistant",
        },
      ],
      nodes,
      source: {
        platform: provider.id,
        url: ctx.url,
        extractedAt: new Date().toISOString(),
        pluginId: "universal-web-chat",
        pluginVersion: "1.0.0",
      },
    };
  },
};

function findProvider(url: string): UniversalProvider | null {
  return UNIVERSAL_PROVIDERS.find((provider) => provider.match(url)) ?? null;
}

function extractMessagesFromDom(
  doc: Document,
  provider: UniversalProvider,
): {
  title?: string;
  messages: Array<{ role: "user" | "assistant"; text: string }>;
} {
  const root = getConversationRoot(doc);

  const roleCandidates = collectRoleCandidates(root, provider);
  const fallbackCandidates =
    roleCandidates.length === 0 ? collectFallbackCandidates(root, provider) : [];
  const merged = mergeConsecutiveMessages(
    sortAndDeduplicateCandidates([...roleCandidates, ...fallbackCandidates]),
  );

  const title = getConversationTitle(doc, provider, merged);
  return { title, messages: merged };
}

function getConversationRoot(doc: Document): ParentNode {
  for (const selector of CONVERSATION_ROOT_SELECTORS) {
    const found = doc.querySelector(selector);
    if (found) return found;
  }
  return doc.body;
}

function collectRoleCandidates(
  root: ParentNode,
  provider: UniversalProvider,
): RoleCandidate[] {
  const userSelectors = [
    ...(provider.userSelectors ?? []),
    ...BASE_USER_SELECTORS,
  ];
  const assistantSelectors = [
    ...(provider.assistantSelectors ?? []),
    ...BASE_ASSISTANT_SELECTORS,
  ];

  const candidates: RoleCandidate[] = [];
  const seen = new Set<Element>();

  for (const selector of userSelectors) {
    for (const el of root.querySelectorAll(selector)) {
      if (seen.has(el)) continue;
      const text = extractText(el);
      if (!text || isNoise(text) || !isMessageElement(el)) continue;
      seen.add(el);
      candidates.push({ role: "user", text, element: el });
    }
  }

  for (const selector of assistantSelectors) {
    for (const el of root.querySelectorAll(selector)) {
      if (seen.has(el)) continue;
      const text = extractText(el);
      if (!text || isNoise(text) || !isMessageElement(el)) continue;
      seen.add(el);
      candidates.push({ role: "assistant", text, element: el });
    }
  }

  return candidates;
}

function collectFallbackCandidates(
  root: ParentNode,
  provider: UniversalProvider,
): RoleCandidate[] {
  const fallbackSelectors = [
    ...(provider.messageSelectors ?? []),
    ...BASE_MESSAGE_SELECTORS,
  ];
  const candidates: RoleCandidate[] = [];
  const seen = new Set<Element>();
  let alternatingRole: "user" | "assistant" = "user";

  for (const selector of fallbackSelectors) {
    for (const el of root.querySelectorAll(selector)) {
      if (seen.has(el)) continue;
      if (!isMessageElement(el)) continue;

      const text = extractText(el);
      if (!text || isNoise(text)) continue;

      const inferred = inferRole(el);
      const role = inferred ?? alternatingRole;
      alternatingRole = alternatingRole === "user" ? "assistant" : "user";

      seen.add(el);
      candidates.push({ role, text, element: el });
    }
  }

  return candidates;
}

function inferRole(element: Element): "user" | "assistant" | null {
  const chunks: string[] = [];
  let cursor: Element | null = element;

  for (let i = 0; i < 4 && cursor; i++) {
    const cls = typeof cursor.className === "string" ? cursor.className : "";
    chunks.push(
      cls,
      cursor.getAttribute("data-role") ?? "",
      cursor.getAttribute("data-message-author-role") ?? "",
      cursor.getAttribute("data-testid") ?? "",
      cursor.getAttribute("aria-label") ?? "",
    );
    cursor = cursor.parentElement;
  }

  const marker = chunks.join(" ").toLowerCase();

  if (/\b(user|human|prompt|question|you)\b/.test(marker)) return "user";
  if (
    /\b(assistant|model|bot|ai|answer|response|copilot|claude|gpt|kimi|qwen|mistral|gemini|perplexity)\b/.test(
      marker,
    )
  ) {
    return "assistant";
  }

  return null;
}

function sortAndDeduplicateCandidates(candidates: RoleCandidate[]): RoleCandidate[] {
  const sorted = [...candidates].sort((a, b) => {
    if (a.element === b.element) return 0;
    const position = a.element.compareDocumentPosition(b.element);
    if (position & Node.DOCUMENT_POSITION_FOLLOWING) return -1;
    if (position & Node.DOCUMENT_POSITION_PRECEDING) return 1;
    return 0;
  });

  const deduped: RoleCandidate[] = [];
  for (const candidate of sorted) {
    const last = deduped[deduped.length - 1];
    if (last?.role === candidate.role && last?.text === candidate.text) {
      continue;
    }
    deduped.push(candidate);
  }

  return deduped;
}

function mergeConsecutiveMessages(
  candidates: RoleCandidate[],
): Array<{ role: "user" | "assistant"; text: string }> {
  const merged: Array<{ role: "user" | "assistant"; text: string }> = [];

  for (const candidate of candidates) {
    const last = merged[merged.length - 1];
    if (last?.role === candidate.role) {
      if (last.text !== candidate.text) {
        last.text = `${last.text}\n${candidate.text}`.trim();
      }
      continue;
    }
    merged.push({ role: candidate.role, text: candidate.text });
  }

  return merged;
}

function getConversationTitle(
  doc: Document,
  provider: UniversalProvider,
  messages: Array<{ role: "user" | "assistant"; text: string }>,
): string | undefined {
  const selectors = [...(provider.titleSelectors ?? []), ...BASE_TITLE_SELECTORS];

  for (const selector of selectors) {
    const title = doc.querySelector(selector)?.textContent;
    const normalized = normalizeTitle(title);
    if (normalized) return normalized;
  }

  const docTitle = normalizeTitle(doc.title);
  if (docTitle) return docTitle;

  const firstUserMessage = messages.find((message) => message.role === "user");
  if (firstUserMessage?.text) {
    return truncateForTitle(firstUserMessage.text, 80);
  }

  return undefined;
}

function normalizeTitle(input?: string | null): string | undefined {
  if (!input) return undefined;
  const normalized = input
    .replace(/\s+/g, " ")
    .replace(/\s*[|·\-]\s*(ChatGPT|Claude|Copilot|Perplexity|Kimi|Poe|Qwen|Grok|Mistral|AI Studio).*$/i, "")
    .trim();
  if (!normalized || isNoise(normalized)) return undefined;
  return truncateForTitle(normalized, 120);
}

function truncateForTitle(value: string, maxLength: number): string {
  if (value.length <= maxLength) return value;
  return `${value.slice(0, maxLength - 3).trim()}...`;
}

function extractText(element: Element): string | null {
  const text =
    element instanceof HTMLElement ? element.innerText : element.textContent;
  if (!text) return null;

  const normalized = text
    .replace(/\u00a0/g, " ")
    .replace(/\r/g, "")
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
    .join("\n")
    .trim();

  if (!normalized) return null;
  return normalized;
}

function isMessageElement(element: Element): boolean {
  if (element.closest("nav, header, footer, aside")) return false;
  if (element.closest("form, textarea, input, button")) return false;

  const hiddenAttr = element.getAttribute("aria-hidden");
  if (hiddenAttr === "true") return false;

  if (element instanceof HTMLElement) {
    const style = getComputedStyle(element);
    if (style.display === "none" || style.visibility === "hidden") return false;
  }

  return true;
}

function isNoise(value: string): boolean {
  const normalized = value.trim();
  if (!normalized) return true;
  if (normalized.length > 0 && normalized.length <= 2) return false;
  return NOISE_PATTERNS.some((pattern) => pattern.test(normalized));
}
