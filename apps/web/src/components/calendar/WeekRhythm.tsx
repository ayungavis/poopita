import { type CalendarCell, sampleWeeks, stoolBand } from "../../content/sampleMonth";

function cellTone(cell: CalendarCell): string {
  if (cell.day === null) {
    return "blank";
  }
  const { mark } = cell;
  if (mark.kind !== "logged") {
    return mark.kind;
  }
  const [first] = mark.types;
  return first === undefined ? "unknown" : stoolBand(first);
}

export function WeekRhythm({ label }: { label: string }) {
  return (
    <figure className="rhythm" aria-label={label}>
      {sampleWeeks().map((week) => (
        <div
          key={week.map((cell) => (cell.day === null ? cell.key : cell.day)).join("-")}
          className="rhythm-week"
        >
          {week.map((cell) => (
            <span
              key={cell.day === null ? cell.key : cell.day}
              className="rhythm-cell"
              data-tone={cellTone(cell)}
            />
          ))}
        </div>
      ))}
    </figure>
  );
}
