import { getAllPlugins } from "@grabber/core-plugins";

export const GRABBER_COMPONENT_NAME = "grabber-root";

export const EXTENSION_RUNTIME_MESSAGE = {
  COPY_CURRENT: "grabber:copy-current",
  SAVE_CURRENT: "grabber:save-current",
  SAVE_BUNDLE: "grabber:save-bundle",
} as const;

export const EXTENSION_WINDOW_EVENT = {
  URL_CHANGE: "grabber:url-change",
  COPY_CURRENT: "grabber:copy-current-window",
  SAVE_CURRENT: "grabber:save-current-window",
  COPY_SUCCESS: "grabber:copy-success",
  COPY_ERROR: "grabber:copy-error",
} as const;

export type ExtensionRuntimeMessageType =
  (typeof EXTENSION_RUNTIME_MESSAGE)[keyof typeof EXTENSION_RUNTIME_MESSAGE];

export function isSupportedTabUrl(url?: string): boolean {
  if (!url) return false;
  return getAllPlugins().some((p) => p.urls.match(url));
}
