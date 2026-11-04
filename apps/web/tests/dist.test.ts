import { describe, expect, test } from "bun:test";
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { join, relative } from "node:path";

const distDir = join(import.meta.dir, "..", "dist");

if (!existsSync(distDir)) {
  throw new Error(`No build found at ${distDir}. Run "bun run build" before "bun run test".`);
}

function htmlFiles(directory: string): string[] {
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) {
      return htmlFiles(path);
    }
    return entry.name.endsWith(".html") ? [path] : [];
  });
}

function attributeValues(html: string, pattern: RegExp): string[] {
  return [...html.matchAll(pattern)].map((match) => match[1] ?? "");
}

function resolvesInDist(href: string): boolean {
  const path = href.split("#")[0] ?? "";
  if (path === "/") {
    return true;
  }
  const target = join(distDir, path);
  return existsSync(path.endsWith("/") ? join(target, "index.html") : target);
}

const pages = htmlFiles(distDir).map((file) => ({
  name: relative(distDir, file),
  html: readFileSync(file, "utf8"),
}));
const localizedPages = pages.filter((page) => page.name !== "404.html");

describe("built site", () => {
  test("builds every page in both languages plus a 404", () => {
    expect(pages.map((page) => page.name).toSorted()).toEqual([
      "404.html",
      "en/index.html",
      "en/privacy/index.html",
      "en/support/index.html",
      "en/terms/index.html",
      "id/index.html",
      "id/privacy/index.html",
      "id/support/index.html",
      "id/terms/index.html",
    ]);
  });

  test.each(pages)("$name ships no executable JavaScript", ({ html }) => {
    const scriptTypes = attributeValues(html, /<script\b([^>]*)>/g);
    expect(scriptTypes.every((attributes) => attributes.includes('type="application/ld+json"'))).toBe(true);
    expect(html).not.toMatch(/\son[a-z]+="/);
  });

  test.each(localizedPages)(
    "$name declares its language, title, description and canonical URL",
    ({ name, html }) => {
      const locale = name.split("/")[0];
      expect(html).toContain(`<html lang="${locale}">`);
      expect(html).toMatch(/<title>[^<]+<\/title>/);
      expect(html).toMatch(/<meta name="description" content="[^"]+">/);
      expect(html).toContain(
        `<link rel="canonical" href="https://poopita.ayungavis.com/${name.replace("index.html", "")}">`,
      );
    },
  );

  test.each(localizedPages)("$name links every language version", ({ html }) => {
    expect(attributeValues(html, /hreflang="([^"]+)"/g).filter((value) => value !== "")).toEqual(
      expect.arrayContaining(["en", "id", "x-default"]),
    );
  });

  test.each(pages)("$name only links to pages that exist", ({ html }) => {
    const internalLinks = attributeValues(html, /href="(\/[^"]*)"/g);
    expect(internalLinks.filter((href) => !resolvesInDist(href))).toEqual([]);
  });

  test.each(pages)("$name gives every image an alt attribute", ({ html }) => {
    const images = html.match(/<img\b[^>]*>/g) ?? [];
    expect(images.filter((image) => !/\salt="/.test(image))).toEqual([]);
  });

  test("lists every localized page in the sitemap", () => {
    const sitemap = readFileSync(join(distDir, "sitemap-0.xml"), "utf8");
    for (const page of localizedPages) {
      expect(sitemap).toContain(`https://poopita.ayungavis.com/${page.name.replace("index.html", "")}`);
    }
  });
});
