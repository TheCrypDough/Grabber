import { clsx, type ClassValue } from "clsx";
import { EXTENSION_RUNTIME_MESSAGE } from "~/constants/extension-runtime";

export function cn(...inputs: ClassValue[]) {
  return clsx(inputs);
}

export async function writeToClipboard(text: string): Promise<void> {
  try {
    await navigator.clipboard.writeText(text);
  } catch {
    // Fallback: execCommand
    const textarea = document.createElement("textarea");
    textarea.value = text;
    textarea.style.position = "fixed";
    textarea.style.left = "-9999px";
    textarea.style.top = "-9999px";
    document.body.appendChild(textarea);
    textarea.select();
    document.execCommand("copy");
    document.body.removeChild(textarea);
  }
}

function slugify(value: string, maxLength = 64): string {
  const slug = value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .replace(/-{2,}/g, "-")
    .slice(0, maxLength);
  return slug || "unknown";
}

function parseFrontmatter(markdown: string): Record<string, string> {
  const trimmed = markdown.trimStart();
  if (!trimmed.startsWith("---\n")) return {};

  const lines = trimmed.split("\n");
  if (lines.length < 3) return {};
  const endIndex = lines.indexOf("---", 1);
  if (endIndex <= 1) return {};

  const frontmatter: Record<string, string> = {};
  for (const line of lines.slice(1, endIndex)) {
    const sep = line.indexOf(":");
    if (sep <= 0) continue;
    const key = line.slice(0, sep).trim();
    const rawValue = line.slice(sep + 1).trim();
    const value = rawValue.replace(/^"(.*)"$/, "$1").trim();
    if (!key || !value) continue;
    frontmatter[key] = value;
  }
  return frontmatter;
}

function formatTimestamp(rawDate?: string): string {
  const parsed = rawDate ? new Date(rawDate) : new Date();
  const date = Number.isNaN(parsed.getTime()) ? new Date() : parsed;

  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, "0");
  const d = String(date.getUTCDate()).padStart(2, "0");
  const hh = String(date.getUTCHours()).padStart(2, "0");
  const mm = String(date.getUTCMinutes()).padStart(2, "0");
  const ss = String(date.getUTCSeconds()).padStart(2, "0");
  return `${y}${m}${d}-${hh}${mm}${ss}`;
}

function parseHost(rawUrl?: string): string {
  if (!rawUrl) return "unknown";
  try {
    return new URL(rawUrl).hostname || "unknown";
  } catch {
    return "unknown";
  }
}

function fallbackContextFromBody(markdown: string): string {
  const withoutFrontmatter = markdown.replace(/^---[\s\S]*?\n---\n?/, "");
  const lines = withoutFrontmatter
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
    .filter((line) => !line.startsWith("## "))
    .filter((line) => !line.startsWith("> "));
  return lines[0] ?? "conversation";
}

export function buildBundleFilename(markdown: string): string {
  const fm = parseFrontmatter(markdown);
  const timestamp = formatTimestamp(fm.date);
  const source = slugify(fm.source ?? "unknown", 24);
  const host = slugify(parseHost(fm.url), 28);
  const context = slugify(
    fm.title ?? fallbackContextFromBody(markdown),
    64,
  );
  return `${timestamp}_${source}@${host}_${context}.md`;
}

export function downloadMarkdown(markdown: string, filename?: string): string {
  const finalFilename = filename ?? buildBundleFilename(markdown);
  const blob = new Blob([markdown], {
    type: "text/markdown;charset=utf-8",
  });
  const url = URL.createObjectURL(blob);

  try {
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = finalFilename;
    anchor.style.display = "none";
    document.body.appendChild(anchor);
    anchor.click();
    document.body.removeChild(anchor);
  } finally {
    setTimeout(() => URL.revokeObjectURL(url), 0);
  }

  return finalFilename;
}

interface SaveBundleResponse {
  ok: boolean;
  filename?: string;
}

function isSaveBundleResponse(value: unknown): value is SaveBundleResponse {
  if (!value || typeof value !== "object") return false;
  const v = value as Record<string, unknown>;
  if (typeof v.ok !== "boolean") return false;
  if (v.filename !== undefined && typeof v.filename !== "string") return false;
  return true;
}

export async function saveMarkdown(markdown: string): Promise<string> {
  const filename = buildBundleFilename(markdown);

  try {
    const response: unknown = await browser.runtime.sendMessage({
      type: EXTENSION_RUNTIME_MESSAGE.SAVE_BUNDLE,
      payload: {
        markdown,
        filename,
      },
    });

    if (isSaveBundleResponse(response) && response.filename) {
      return response.filename;
    }
  } catch {
    // Fallback to direct browser download if background message fails.
  }

  return downloadMarkdown(markdown, filename);
}
