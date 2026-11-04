import react from "@astrojs/react";
import sitemap from "@astrojs/sitemap";
import { defineConfig, envField } from "astro/config";
import { site } from "./src/config/site";

export default defineConfig({
  site: site.origin,
  output: "static",
  trailingSlash: "always",
  build: { format: "directory", inlineStylesheets: "never" },
  vite: { build: { assetsInlineLimit: 0 } },
  integrations: [
    react(),
    sitemap({
      filter: (page) => !page.endsWith("/404/"),
      i18n: { defaultLocale: "en", locales: { en: "en", id: "id" } },
    }),
  ],
  env: {
    schema: {
      APP_STORE_ID: envField.number({
        context: "server",
        access: "public",
        optional: true,
        int: true,
        gt: 0,
      }),
    },
    validateSecrets: true,
  },
});
