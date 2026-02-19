import { registerBuiltinPlugins } from "@ctxport/core-plugins";
import {
  EXTENSION_RUNTIME_MESSAGE,
  isSupportedTabUrl,
} from "~/constants/extension-runtime";
import { applySubfolder, getSaveSettings } from "~/lib/save-settings";

// Must register plugins before isSupportedTabUrl can work
registerBuiltinPlugins();

interface SaveBundleRequest {
  type: typeof EXTENSION_RUNTIME_MESSAGE.SAVE_BUNDLE;
  payload?: {
    markdown?: string;
    filename?: string;
  };
}

async function sendMessageToTab(
  tabId: number,
  message: { type: string },
): Promise<void> {
  try {
    await browser.tabs.sendMessage(tabId, message);
  } catch {
    // Content script not mounted in this tab
  }
}

async function getActiveTab() {
  const tabs = await browser.tabs.query({
    active: true,
    currentWindow: true,
  });
  return tabs[0] ?? null;
}

function toDataUrl(markdown: string): string {
  return `data:text/markdown;charset=utf-8,${encodeURIComponent(markdown)}`;
}

async function saveBundleFromPayload(payload?: {
  markdown?: string;
  filename?: string;
}): Promise<{ filename: string; downloadId: number }> {
  const markdown = payload?.markdown;
  const suggestedFilename = payload?.filename;

  if (!markdown || !suggestedFilename) {
    throw new Error("Missing markdown payload");
  }

  const settings = await getSaveSettings();
  const filename = applySubfolder(suggestedFilename, settings.saveSubfolder);

  const downloadId = await browser.downloads.download({
    url: toDataUrl(markdown),
    filename,
    saveAs: settings.saveMode === "prompt",
    conflictAction: "uniquify",
  });

  return { filename, downloadId };
}

export default defineBackground(() => {
  browser.runtime.onInstalled.addListener((details) => {
    if (details.reason === "install") {
      void browser.runtime.openOptionsPage();
    }
  });

  browser.runtime.onMessage.addListener((message: unknown) => {
    const typed = message as SaveBundleRequest;
    if (typed?.type !== EXTENSION_RUNTIME_MESSAGE.SAVE_BUNDLE) {
      return undefined;
    }

    return saveBundleFromPayload(typed.payload)
      .then((result) => ({
        ok: true,
        filename: result.filename,
        downloadId: result.downloadId,
      }))
      .catch((error: unknown) => ({
        ok: false,
        error: error instanceof Error ? error.message : "Save failed",
      }));
  });

  // Toolbar icon click: copy current conversation
  browser.action.onClicked.addListener((tab) => {
    void (async () => {
      if (!tab.id || !isSupportedTabUrl(tab.url)) return;
      await sendMessageToTab(tab.id, {
        type: EXTENSION_RUNTIME_MESSAGE.COPY_CURRENT,
      });
    })();
  });

  // Keyboard shortcuts
  browser.commands.onCommand.addListener((command) => {
    void (async () => {
      const tab = await getActiveTab();
      if (!tab?.id || !isSupportedTabUrl(tab.url)) return;

      if (command === "copy-current") {
        await sendMessageToTab(tab.id, {
          type: EXTENSION_RUNTIME_MESSAGE.COPY_CURRENT,
        });
        return;
      }

      if (command === "save-current") {
        await sendMessageToTab(tab.id, {
          type: EXTENSION_RUNTIME_MESSAGE.SAVE_CURRENT,
        });
      }
    })();
  });
});
