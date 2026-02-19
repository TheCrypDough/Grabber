import { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import {
  getSaveSettings,
  setSaveSettings,
  type SaveMode,
} from "~/lib/save-settings";

const FONT_STACK =
  '"Segoe UI", "SF Pro Text", -apple-system, BlinkMacSystemFont, sans-serif';

function SetupPage() {
  const [saveMode, setSaveMode] = useState<SaveMode>("default");
  const [saveSubfolder, setSaveSubfolder] = useState("convos");
  const [status, setStatus] = useState<string>("Loading settings...");
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    void (async () => {
      const settings = await getSaveSettings();
      setSaveMode(settings.saveMode);
      setSaveSubfolder(settings.saveSubfolder || "convos");
      setStatus("Configure where Grabber saves markdown files.");
    })();
  }, []);

  const handleSave = async () => {
    setIsSaving(true);
    try {
      const saved = await setSaveSettings({
        saveMode,
        saveSubfolder,
      });
      setSaveMode(saved.saveMode);
      setSaveSubfolder(saved.saveSubfolder || "convos");
      setStatus("Saved. New conversations will use this setup.");
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <div
      style={{
        minHeight: "100vh",
        margin: 0,
        padding: "28px 20px",
        background:
          "radial-gradient(1200px 500px at 10% -10%, #e0f2fe 0%, #f8fafc 45%, #eef2ff 100%)",
        color: "#0f172a",
        fontFamily: FONT_STACK,
      }}
    >
      <div
        style={{
          maxWidth: 760,
          margin: "0 auto",
          backgroundColor: "rgba(255, 255, 255, 0.82)",
          border: "1px solid rgba(15, 23, 42, 0.10)",
          borderRadius: 16,
          backdropFilter: "blur(8px)",
          boxShadow: "0 12px 40px rgba(15, 23, 42, 0.08)",
          padding: 24,
        }}
      >
        <h1
          style={{
            margin: 0,
            fontSize: 28,
            lineHeight: 1.2,
            letterSpacing: "-0.02em",
          }}
        >
          Grabber Setup
        </h1>
        <p
          style={{
            marginTop: 8,
            marginBottom: 24,
            color: "#334155",
            fontSize: 15,
            lineHeight: 1.5,
          }}
        >
          End copy-paste time waste. Choose how one-click Save downloads your
          full AI conversations.
        </p>

        <section
          style={{
            display: "grid",
            gap: 14,
            padding: 16,
            borderRadius: 12,
            border: "1px solid rgba(15, 23, 42, 0.08)",
            backgroundColor: "rgba(255, 255, 255, 0.8)",
          }}
        >
          <label
            style={{
              display: "grid",
              gap: 8,
            }}
          >
            <span
              style={{
                fontWeight: 600,
                fontSize: 14,
              }}
            >
              Save mode
            </span>
            <select
              value={saveMode}
              onChange={(e) => setSaveMode(e.target.value as SaveMode)}
              style={{
                padding: "10px 12px",
                fontSize: 14,
                borderRadius: 10,
                border: "1px solid rgba(15, 23, 42, 0.15)",
                backgroundColor: "#ffffff",
                color: "#0f172a",
              }}
            >
              <option value="default">Save directly (fast, no prompt)</option>
              <option value="prompt">Ask where to save every time</option>
            </select>
          </label>

          <label
            style={{
              display: "grid",
              gap: 8,
            }}
          >
            <span
              style={{
                fontWeight: 600,
                fontSize: 14,
              }}
            >
              Download subfolder
            </span>
            <input
              type="text"
              value={saveSubfolder}
              onChange={(e) => setSaveSubfolder(e.target.value)}
              placeholder="convos"
              style={{
                padding: "10px 12px",
                fontSize: 14,
                borderRadius: 10,
                border: "1px solid rgba(15, 23, 42, 0.15)",
                backgroundColor: "#ffffff",
                color: "#0f172a",
              }}
            />
            <span
              style={{
                color: "#475569",
                fontSize: 12,
                lineHeight: 1.4,
              }}
            >
              This is relative to your browser Downloads folder. Example:
              `convos/ai`.
            </span>
          </label>
        </section>

        <div
          style={{
            marginTop: 16,
            display: "flex",
            alignItems: "center",
            gap: 10,
          }}
        >
          <button
            type="button"
            onClick={handleSave}
            disabled={isSaving}
            style={{
              padding: "10px 14px",
              borderRadius: 10,
              border: "none",
              fontSize: 14,
              fontWeight: 600,
              cursor: isSaving ? "wait" : "pointer",
              color: "#ffffff",
              backgroundColor: "#0284c7",
              opacity: isSaving ? 0.7 : 1,
            }}
          >
            {isSaving ? "Saving..." : "Save Setup"}
          </button>
          <button
            type="button"
            onClick={() => window.close()}
            style={{
              padding: "10px 14px",
              borderRadius: 10,
              border: "1px solid rgba(15, 23, 42, 0.12)",
              fontSize: 14,
              fontWeight: 600,
              cursor: "pointer",
              color: "#0f172a",
              backgroundColor: "#ffffff",
            }}
          >
            Close
          </button>
        </div>

        <p
          style={{
            marginTop: 14,
            marginBottom: 0,
            color: "#0f766e",
            fontSize: 13,
            lineHeight: 1.5,
          }}
        >
          {status}
        </p>
      </div>
    </div>
  );
}

const root = createRoot(document.getElementById("root")!);
root.render(<SetupPage />);
