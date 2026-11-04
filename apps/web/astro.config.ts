import react from "@astrojs/react";
import sitemap from "@astrojs/sitemap";
import { rename, rmdir } from "node:fs/promises";
import type { AstroIntegration } from "astro";
import { defineConfig, envField } from "astro/config";
import { site } from "./src/config/site";
import { defaultLocale, locales } from "./src/i18n/locales";

const localizedNotFoundPages: AstroIntegration = {
  name: "localized-not-found-pages",
  hooks: {
    "astro:build:done": async ({ dir }) => {
      const moves = locales
        .filter((candidate) => candidate !== defaultLocale)
        .map(async (locale) => {
          await rename(new URL(`${locale}/404/index.html`, dir), new URL(`${locale}/404.html`, dir));
          await rmdir(new URL(`${locale}/404/`, dir));
        });
      await Promise.all(moves);
    },
  },
};

export default defineConfig({
  site: site.origin,
  output: "static",
  trailingSlash: "ignore",
  build: { format: "directory", inlineStylesheets: "never" },
  vite: { build: { assetsInlineLimit: 0 } },
  integrations: [
    react(),
    localizedNotFoundPages,
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
