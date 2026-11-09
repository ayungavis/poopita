import type { DayMark } from "../../content/sampleMonth";
import { Doodle } from "../Doodle";
import { bristolDoodle } from "../doodlePaths";

export function DayMarkGlyph({ mark }: { mark: DayMark }) {
  switch (mark.kind) {
    case "logged":
      return <LoggedGlyph types={mark.types} />;
    case "none":
      return <TickGlyph />;
    case "unknown":
    case "open":
    case "untracked":
    case "future":
      return null;
  }
}

function LoggedGlyph({ types }: { types: Extract<DayMark, { kind: "logged" }>["types"] }) {
  const [first] = types;
  if (first === undefined) {
    return null;
  }
  return (
    <span className="day-logged">
      <Doodle name={bristolDoodle(first)} />
      <span className="day-dots" aria-hidden>
        {"•".repeat(types.length)}
      </span>
    </span>
  );
}

function TickGlyph() {
  return (
    <svg className="day-tick" viewBox="0 0 24 24" aria-hidden focusable="false">
      <path d="M5 12.5 L10 17 L19 7.5" />
    </svg>
  );
}
