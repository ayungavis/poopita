export type BristolType = 1 | 2 | 3 | 4 | 5 | 6 | 7;

export type DayMark =
  | { kind: "untracked" }
  | { kind: "logged"; types: readonly BristolType[] }
  | { kind: "none" }
  | { kind: "unknown" }
  | { kind: "open" }
  | { kind: "future" };

export interface SampleDay {
  day: number;
  mark: DayMark;
}

const logged = (...types: BristolType[]): DayMark => ({ kind: "logged", types });
const none: DayMark = { kind: "none" };
const unknown: DayMark = { kind: "unknown" };

const marks: readonly DayMark[] = [
  { kind: "untracked" },
  { kind: "untracked" },
  { kind: "untracked" },
  logged(4),
  logged(3),
  logged(4, 4),
  none,
  logged(2),
  logged(3),
  unknown,
  logged(4),
  logged(4),
  logged(5),
  logged(4),
  unknown,
  unknown,
  logged(3),
  logged(4, 6),
  none,
  logged(4),
  logged(4),
  logged(3),
  unknown,
  logged(4),
  logged(4),
  none,
  logged(3),
  { kind: "open" },
  { kind: "future" },
  { kind: "future" },
  { kind: "future" },
];

export const sampleMonth = {
  year: 2026,
  monthIndex: 9,
  today: 28,
  focusDay: 14,
  days: marks.map((mark, index): SampleDay => ({ day: index + 1, mark })),
} as const;

export function leadingBlankDays(year: number, monthIndex: number): number {
  const weekday = new Date(Date.UTC(year, monthIndex, 1)).getUTCDay();
  return (weekday + 6) % 7;
}

export type CalendarCell = SampleDay | { day: null; key: string };

export function sampleWeeks(): CalendarCell[][] {
  const { year, monthIndex, days } = sampleMonth;
  const blanks = Array.from({ length: leadingBlankDays(year, monthIndex) }, (_, index): CalendarCell => ({
    day: null,
    key: `lead-${index}`,
  }));
  const cells: CalendarCell[] = [...blanks, ...days];
  const trailing = (7 - (cells.length % 7)) % 7;
  const padded = [
    ...cells,
    ...Array.from({ length: trailing }, (_, index): CalendarCell => ({ day: null, key: `trail-${index}` })),
  ];
  return Array.from({ length: padded.length / 7 }, (_, week) => padded.slice(week * 7, week * 7 + 7));
}

export type StoolBand = "hard" | "usual" | "loose";

export function stoolBand(type: BristolType): StoolBand {
  if (type <= 2) {
    return "hard";
  }
  return type <= 5 ? "usual" : "loose";
}
