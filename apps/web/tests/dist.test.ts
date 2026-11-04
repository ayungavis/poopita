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
      "id/index.html",
      "id/privacy/index.html",
      "id/support/index.html",
      "id/terms/index.html",
      "index.html",
      "privacy/index.html",
      "support/index.html",
      "terms/index.html",
    ]);
  });

  test.each(pages)("$name runs only the theme and header scripts, both from files", ({ html }) => {
    const executable = attributeValues(html, /<script\b([^>]*)>/g).filter(
      (attributes) => !attributes.includes('type="application/ld+json"'),
    );
    expect(executable).toHaveLength(2);
    expect(executable[0]).toBe(' src="/theme.js"');
    expect(executable[1]).toMatch(/^ type="module" src="\/_astro\/[^"]+\.js"$/);
    expect(html.indexOf('src="/theme.js"')).toBeLessThan(html.indexOf("</head>"));
    expect(existsSync(join(distDir, "theme.js"))).toBe(true);
    expect(html).not.toMatch(/<script(?: type="module")?>/);
    expect(html).not.toMatch(/\son[a-z]+="/);
  });

  test.each(localizedPages)(
    "$name declares its language, title, description and canonical URL",
    ({ name, html }) => {
      const locale = name.startsWith("id/") ? "id" : "en";
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

  test("redirects old /en/ links to the unprefixed English pages", () => {
    expect(readFileSync(join(distDir, "_redirects"), "utf8")).toContain("/en/* /:splat 301");
  });

  test("lets the page load scripts from its own origin only", () => {
    expect(readFileSync(join(distDir, "_headers"), "utf8")).toContain("script-src 'self';");
  });

  test("lists every localized page in the sitemap", () => {
    const sitemap = readFileSync(join(distDir, "sitemap-0.xml"), "utf8");
    for (const page of localizedPages) {
      expect(sitemap).toContain(`https://poopita.ayungavis.com/${page.name.replace("index.html", "")}`);
    }
  });
});
