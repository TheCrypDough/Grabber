import { EXTENSION_HOST_PERMISSIONS } from "@grabber/core-plugins";
import tailwindcss from "@tailwindcss/vite";
import tsconfigPaths from "vite-tsconfig-paths";
import { defineConfig } from "wxt";
import { toUtf8 } from "./scripts/vite-plugin-to-utf8";

export default defineConfig({
  manifest: {
    name: "Grabber",
    description: "End copy-paste time waste. Save AI conversations instantly.",
    version: "0.1.0",
    content_security_policy: {
      extension_pages: "script-src 'self'; object-src 'self';",
    },
    permissions: ["activeTab", "storage", "downloads"],
    host_permissions: EXTENSION_HOST_PERMISSIONS,
    icons: {
      16: "icon/16.png",
      32: "icon/32.png",
      48: "icon/48.png",
      128: "icon/128.png",
    },
    action: {
      default_title: "Grabber",
      default_icon: {
        16: "icon/16.png",
        32: "icon/32.png",
        48: "icon/48.png",
        128: "icon/128.png",
      },
    },
    options_ui: {
      page: "options.html",
      open_in_tab: true,
    },
    commands: {
      "copy-current": {
        suggested_key: {
          default: "Alt+Shift+C",
          mac: "Alt+Shift+C",
        },
        description: "Copy current conversation",
      },
      "save-current": {
        suggested_key: {
          default: "Alt+Shift+S",
          mac: "Alt+Shift+S",
        },
        description: "Save current conversation as markdown",
      },
    },
  },
  srcDir: "src",
  outDir: "dist",
  modules: ["@wxt-dev/module-react"],
  vite: () => ({
    plugins: [toUtf8(), tailwindcss(), tsconfigPaths()],
    resolve: {
      conditions: ["development", "import", "browser", "default"],
    },
    optimizeDeps: {
      exclude: ["@grabber/core-plugins", "@grabber/core-markdown"],
    },
    build: {
      sourcemap: false,
    },
  }),
});
