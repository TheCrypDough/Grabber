import {
  serializeConversation,
  type BundleFormatType,
} from "@grabber/core-markdown";
import { findPlugin } from "@grabber/core-plugins";
import { useState, useCallback } from "react";
import { saveMarkdown, writeToClipboard } from "~/lib/utils";

export type CopyState = "idle" | "loading" | "success" | "error";
export type ConversationAction = "copy" | "save";

export interface CopyResult {
  action: ConversationAction;
  filename?: string;
  messageCount: number;
  estimatedTokens: number;
}

export function useCopyConversation() {
  const [state, setState] = useState<CopyState>("idle");
  const [result, setResult] = useState<CopyResult | null>(null);
  const [error, setError] = useState<string | null>(null);

  const run = useCallback(
    async (
      action: ConversationAction,
      format: BundleFormatType = "full",
    ): Promise<void> => {
      setState("loading");
      setError(null);
      setResult(null);

      try {
        const plugin = findPlugin(window.location.href);
        if (!plugin) throw new Error("No plugin for this page");

        const bundle = await plugin.extract({
          url: window.location.href,
          document,
        });

        const serialized = serializeConversation(bundle, { format });
        let filename: string | undefined;

        if (action === "copy") {
          await writeToClipboard(serialized.markdown);
        } else {
          filename = await saveMarkdown(serialized.markdown);
        }

        setResult({
          action,
          filename,
          messageCount: serialized.messageCount,
          estimatedTokens: serialized.estimatedTokens,
        });
        setState("success");

        setTimeout(() => {
          setState("idle");
          setResult(null);
        }, 1500);
      } catch (err) {
        const message = err instanceof Error ? err.message : "Unknown error";
        setError(message);
        setState("error");

        setTimeout(() => {
          setState("idle");
          setError(null);
        }, 3000);
      }
    },
    [],
  );

  const copy = useCallback(async (format: BundleFormatType = "full") => {
    await run("copy", format);
  }, [run]);

  const save = useCallback(async (format: BundleFormatType = "full") => {
    await run("save", format);
  }, [run]);

  return { state, result, error, copy, save };
}
