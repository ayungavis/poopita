import { describe, expect, test } from "bun:test";
import { locales, parseLocale } from "../src/i18n/locales";
import { alternatesFor, localeFromParam, pageIds, pathFor } from "../src/lib/routes";

describe("pathFor", () => {
  test("serves English without a prefix", () => {
    expect(pathFor("en", "home")).toBe("/");
    expect(pathFor("en", "privacy")).toBe("/privacy/");
  });

  test("prefixes other locales and ends with a slash", () => {
    expect(pathFor("id", "home")).toBe("/id/");
    expect(pathFor("id", "privacy")).toBe("/id/privacy/");
  });
});

describe("alternatesFor", () => {
  test.each([...pageIds])("lists every locale plus x-default for %s", (page) => {
    const alternates = alternatesFor(page);
    expect(alternates.map((alternate) => alternate.hreflang)).toEqual([...locales, "x-default"]);
    expect(alternates.every((alternate) => alternate.href.startsWith("https://poopita.ayungavis.com/"))).toBe(
      true,
    );
  });

  test("points x-default at the English page", () => {
    const xDefault = alternatesFor("support").find((alternate) => alternate.hreflang === "x-default");
    expect(xDefault?.href).toBe("https://poopita.ayungavis.com/support/");
  });
});

describe("parseLocale", () => {
  test("accepts a supported locale", () => {
    expect(parseLocale("id")).toBe("id");
  });

  test.each([undefined, "fr", "EN", 1])("rejects %p with a message naming the supported locales", (value) => {
    expect(() => parseLocale(value)).toThrow("Expected one of: en, id.");
  });
});

describe("localeFromParam", () => {
  test("falls back to English when the path has no locale", () => {
    expect(localeFromParam(undefined)).toBe("en");
  });

  test("rejects a locale the site does not serve", () => {
    expect(() => localeFromParam("fr")).toThrow("Expected one of: en, id.");
  });
});
