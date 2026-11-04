import { describe, expect, test } from "bun:test";
import { messagesFor } from "../src/i18n";

type Shape = string | Shape[] | { [key: string]: Shape };

function shapeOf(value: unknown): Shape {
  if (typeof value === "string") {
    return "string";
  }
  if (Array.isArray(value)) {
    return value.map(shapeOf);
  }
  if (typeof value === "object" && value !== null) {
    return Object.fromEntries(Object.entries(value).map(([key, entry]) => [key, shapeOf(entry)]));
  }
  throw new TypeError(`Unexpected message value: ${String(value)}`);
}

function emptyStrings(value: unknown, path = "messages"): string[] {
  if (typeof value === "string") {
    return value.trim() === "" ? [path] : [];
  }
  if (typeof value === "object" && value !== null) {
    return Object.entries(value).flatMap(([key, entry]) => emptyStrings(entry, `${path}.${key}`));
  }
  return [];
}

describe("messages", () => {
  const en = messagesFor("en");
  const id = messagesFor("id");

  test("Indonesian has the same structure as English, down to list lengths", () => {
    expect(shapeOf(id)).toEqual(shapeOf(en));
  });

  test.each([
    ["en", en],
    ["id", id],
  ])("%s has no empty strings", (_, messages) => {
    expect(emptyStrings(messages)).toEqual([]);
  });

  test("legal section ids are unique and match across languages", () => {
    for (const document of ["privacy", "terms"] as const) {
      const ids = en[document].sections.map((section) => section.id);
      expect(new Set(ids).size).toBe(ids.length);
      expect(id[document].sections.map((section) => section.id)).toEqual(ids);
    }
  });
});
