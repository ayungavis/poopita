import { describe, expect, test } from "bun:test";
import { locales, parseLocale } from "../src/i18n/locales";
import { alternatesFor, pageIds, pathFor } from "../src/lib/routes";

describe("pathFor", () => {
  test("prefixes every page with its locale and ends with a slash", () => {
    expect(pathFor("en", "home")).toBe("/en/");
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
    expect(xDefault?.href).toBe("https://poopita.ayungavis.com/en/support/");
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
