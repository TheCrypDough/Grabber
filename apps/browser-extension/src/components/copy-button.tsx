import type { BundleFormatType } from "@ctxport/core-markdown";
import { useState, useCallback, useRef, useEffect } from "react";
import { ContextMenu } from "./context-menu";
import { EXTENSION_WINDOW_EVENT } from "~/constants/extension-runtime";
import {
  useCopyConversation,
  type ConversationAction,
  type CopyState,
} from "~/hooks/use-copy-conversation";

const MOTION = {
  instant: "100ms",
  fast: "150ms",
  normal: "250ms",
  smooth: "350ms",
  easeOut: "cubic-bezier(0.16, 1, 0.3, 1)",
  easeIn: "cubic-bezier(0.55, 0, 1, 0.45)",
  spring: "cubic-bezier(0.34, 1.56, 0.64, 1)",
  springSubtle: "cubic-bezier(0.22, 1.2, 0.36, 1)",
} as const;

interface CopyButtonProps {
  mode?: ConversationAction;
  onToast: (data: {
    title: string;
    subtitle?: string;
    type: "success" | "error";
    isLarge?: boolean;
  }) => void;
}

export function CopyButton({ mode = "copy", onToast }: CopyButtonProps) {
  const { state, result, error, copy, save } = useCopyConversation();
  const [menu, setMenu] = useState<{ x: number; y: number } | null>(null);
  const [hovered, setHovered] = useState(false);
  const [pressed, setPressed] = useState(false);
  const [iconAnimated, setIconAnimated] = useState(false);
  const prevStateRef = useRef<CopyState>("idle");

  const handleClick = useCallback(async () => {
    if (mode === "save") {
      await save("full");
      return;
    }
    await copy("full");
  }, [copy, mode, save]);

  // Respond to runtime window event (from popup / keyboard shortcut)
  useEffect(() => {
    const handler = () => {
      if (mode === "save") {
        void save("full");
        return;
      }
      void copy("full");
    };
    const eventName =
      mode === "save"
        ? EXTENSION_WINDOW_EVENT.SAVE_CURRENT
        : EXTENSION_WINDOW_EVENT.COPY_CURRENT;
    window.addEventListener(eventName, handler);
    return () =>
      window.removeEventListener(eventName, handler);
  }, [copy, mode, save]);

  const handleContextMenu = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setMenu({ x: e.clientX, y: e.clientY });
  }, []);

  const handleFormatSelect = useCallback(
    async (format: BundleFormatType) => {
      if (mode === "save") {
        await save(format);
        return;
      }
      await copy(format);
    },
    [copy, mode, save],
  );

  // Trigger icon scale-in animation on success/error
  useEffect(() => {
    if (state === "success" || state === "error") {
      setIconAnimated(false);
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          setIconAnimated(true);
        });
      });
    }
  }, [state]);

  // Show toast on state change
  useEffect(() => {
    if (prevStateRef.current === state) return;
    prevStateRef.current = state;

    if (state === "success" && result) {
      const tokenStr =
        result.estimatedTokens >= 1000
          ? `~${(result.estimatedTokens / 1000).toFixed(1)}K`
          : `~${result.estimatedTokens}`;
      const isLarge =
        result.messageCount >= 50 || result.estimatedTokens >= 10000;
      onToast({
        title:
          result.action === "save"
            ? "Grabber \u00b7 Saved markdown file"
            : "Grabber \u00b7 Copied to clipboard",
        subtitle:
          result.action === "save"
            ? `${result.messageCount} messages \u00b7 ${tokenStr} tokens \u00b7 ${result.filename ?? "conversation.md"}`
            : `${result.messageCount} messages \u00b7 ${tokenStr} tokens`,
        type: "success",
        isLarge,
      });
    } else if (state === "error" && error) {
      onToast({
        title:
          mode === "save"
            ? "Grabber \u00b7 Save failed"
            : "Grabber \u00b7 Copy failed",
        subtitle: error,
        type: "error",
      });
    }
  }, [state, result, error, mode, onToast]);

  const isIdle = state === "idle";
  const isLoading = state === "loading";

  // Compute button style based on state + hover/pressed
  const buttonStyle: React.CSSProperties = {
    display: "inline-flex",
    alignItems: "center",
    justifyContent: "center",
    width: 32,
    height: 32,
    padding: 0,
    border: "none",
    borderRadius: 8,
    background: hovered && isIdle ? "rgba(128, 128, 128, 0.08)" : "transparent",
    cursor: isLoading ? "wait" : "pointer",
    color: iconColor(state),
    opacity: isLoading ? 0.6 : isIdle && !hovered ? 0.7 : 1,
    transform:
      pressed && (isIdle || isLoading)
        ? "scale(0.88)"
        : hovered && isIdle
          ? "scale(1.08)"
          : "scale(1)",
    transition: pressed
      ? `transform ${MOTION.instant} ${MOTION.easeIn}, opacity ${MOTION.fast} ${MOTION.easeOut}, color ${MOTION.fast} ${MOTION.easeOut}, background ${MOTION.fast} ${MOTION.easeOut}`
      : `transform ${MOTION.fast} ${MOTION.spring}, opacity ${MOTION.fast} ${MOTION.easeOut}, color ${MOTION.fast} ${MOTION.easeOut}, background ${MOTION.fast} ${MOTION.easeOut}`,
  };

  return (
    <>
      <button
        type="button"
        onClick={handleClick}
        onContextMenu={handleContextMenu}
        onMouseEnter={() => setHovered(true)}
        onMouseLeave={() => {
          setHovered(false);
          setPressed(false);
        }}
        onMouseDown={() => setPressed(true)}
        onMouseUp={() => setPressed(false)}
        disabled={isLoading}
        title={
          mode === "save"
            ? "Save as Markdown (Grabber)"
            : "Copy as Context Bundle (Grabber)"
        }
        className={
          mode === "save" ? "ctxport-save-btn" : "ctxport-copy-btn"
        }
        style={buttonStyle}
      >
        <IconForState state={state} animated={iconAnimated} mode={mode} />
      </button>
      {menu && (
        <ContextMenu
          x={menu.x}
          y={menu.y}
          onSelect={handleFormatSelect}
          onClose={() => setMenu(null)}
          action={mode}
        />
      )}
    </>
  );
}

function iconColor(state: CopyState): string {
  switch (state) {
    case "success":
      return "#059669";
    case "error":
      return "#dc2626";
    default:
      return "currentColor";
  }
}

function IconForState({
  state,
  animated,
  mode,
}: {
  state: CopyState;
  animated: boolean;
  mode: ConversationAction;
}) {
  if (state === "loading") {
    return (
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
        <circle
          cx="12"
          cy="12"
          r="9"
          stroke="currentColor"
          strokeWidth="2"
          strokeOpacity="0.2"
        />
        <path
          d="M12 3a9 9 0 0 1 9 9"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
        >
          <animateTransform
            attributeName="transform"
            type="rotate"
            from="0 12 12"
            to="360 12 12"
            dur="0.8s"
            repeatCount="indefinite"
          />
        </path>
      </svg>
    );
  }

  if (state === "success") {
    return (
      <svg
        width="18"
        height="18"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        style={{
          transform: animated ? "scale(1)" : "scale(0.5)",
          opacity: animated ? 1 : 0,
          transition: animated
            ? `transform ${MOTION.normal} ${MOTION.spring}, opacity ${MOTION.fast} ${MOTION.easeOut}`
            : "none",
        }}
      >
        <polyline points="20 6 9 17 4 12" />
      </svg>
    );
  }

  if (state === "error") {
    return (
      <svg
        width="18"
        height="18"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
        style={{
          transform: animated ? "scale(1)" : "scale(0.5)",
          opacity: animated ? 1 : 0,
          transition: animated
            ? `transform ${MOTION.fast} ${MOTION.easeOut}, opacity ${MOTION.fast} ${MOTION.easeOut}`
            : "none",
        }}
      >
        <path d="M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z" />
        <line x1="12" y1="9" x2="12" y2="13" />
        <line x1="12" y1="17" x2="12.01" y2="17" />
      </svg>
    );
  }

  // idle -- clipboard icon
  if (mode === "save") {
    return (
      <svg
        width="18"
        height="18"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
        <polyline points="7 10 12 15 17 10" />
        <line x1="12" y1="15" x2="12" y2="3" />
      </svg>
    );
  }

  // idle -- clipboard icon
  return (
    <svg
      width="18"
      height="18"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <rect x="9" y="9" width="13" height="13" rx="2" ry="2" />
      <path d="M5 15H4a2 2 0 01-2-2V4a2 2 0 012-2h9a2 2 0 012 2v1" />
    </svg>
  );
}
