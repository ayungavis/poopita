import { describe, expect, test } from "bun:test";
import { leadingBlankDays, sampleMonth, sampleWeeks, stoolBand } from "../src/content/sampleMonth";

describe("sample month", () => {
  test("October 2026 starts on a Thursday, three blanks into a Monday-first week", () => {
    expect(leadingBlankDays(2026, 9)).toBe(3);
  });

  test("weeks are seven cells wide and hold every day exactly once, in order", () => {
    const weeks = sampleWeeks();
    expect(weeks.every((week) => week.length === 7)).toBe(true);
    const days = weeks.flat().flatMap((cell) => (cell.day === null ? [] : [cell.day]));
    expect(days).toEqual(sampleMonth.days.map((entry) => entry.day));
  });

  test("today is the one open day, and days after it are still to come", () => {
    const open = sampleMonth.days.filter((entry) => entry.mark.kind === "open");
    expect(open.map((entry) => entry.day)).toEqual([sampleMonth.today]);
    expect(
      sampleMonth.days
        .filter((entry) => entry.day > sampleMonth.today)
        .every((entry) => entry.mark.kind === "future"),
    ).toBe(true);
  });

  test.each([
    [1, "hard"],
    [2, "hard"],
    [3, "usual"],
    [5, "usual"],
    [6, "loose"],
    [7, "loose"],
  ] as const)("Bristol type %i is %s", (type, band) => {
    expect(stoolBand(type)).toBe(band);
  });
});
