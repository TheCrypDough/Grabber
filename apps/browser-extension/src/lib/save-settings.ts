export type SaveMode = "default" | "prompt";

export interface SaveSettings {
  saveMode: SaveMode;
  saveSubfolder: string;
}

const STORAGE_KEYS = {
  saveMode: "grabber.saveMode",
  saveSubfolder: "grabber.saveSubfolder",
} as const;

const DEFAULT_SETTINGS: SaveSettings = {
  saveMode: "default",
  saveSubfolder: "convos",
};

function normalizeSubfolder(input: string): string {
  return input
    .trim()
    .replace(/\\/g, "/")
    .replace(/^\/+|\/+$/g, "")
    .split("/")
    .map((segment) =>
      segment
        .trim()
        .replace(/[^a-zA-Z0-9._-]+/g, "-")
        .replace(/^-+|-+$/g, ""),
    )
    .filter(Boolean)
    .join("/");
}

export function sanitizeSaveSettings(input: Partial<SaveSettings>): SaveSettings {
  const saveMode: SaveMode =
    input.saveMode === "prompt" ? "prompt" : DEFAULT_SETTINGS.saveMode;
  const saveSubfolder = normalizeSubfolder(
    input.saveSubfolder ?? DEFAULT_SETTINGS.saveSubfolder,
  );

  return {
    saveMode,
    saveSubfolder,
  };
}

export async function getSaveSettings(): Promise<SaveSettings> {
  const values = await browser.storage.local.get({
    [STORAGE_KEYS.saveMode]: DEFAULT_SETTINGS.saveMode,
    [STORAGE_KEYS.saveSubfolder]: DEFAULT_SETTINGS.saveSubfolder,
  });

  return sanitizeSaveSettings({
    saveMode: values[STORAGE_KEYS.saveMode] as SaveMode,
    saveSubfolder: values[STORAGE_KEYS.saveSubfolder] as string,
  });
}

export async function setSaveSettings(input: SaveSettings): Promise<SaveSettings> {
  const clean = sanitizeSaveSettings(input);
  await browser.storage.local.set({
    [STORAGE_KEYS.saveMode]: clean.saveMode,
    [STORAGE_KEYS.saveSubfolder]: clean.saveSubfolder,
  });
  return clean;
}

export function applySubfolder(filename: string, subfolder: string): string {
  const cleanSubfolder = normalizeSubfolder(subfolder);
  if (!cleanSubfolder) return filename;
  return `${cleanSubfolder}/${filename}`;
}
