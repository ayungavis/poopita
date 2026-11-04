import { VisuallyHidden } from "@astryxdesign/core/VisuallyHidden";
import type { CSSProperties } from "react";
import { sampleMonth, sampleWeeks } from "../../content/sampleMonth";
import { type Locale, localeDetails } from "../../i18n/locales";
import { DayMarkGlyph } from "./DayMarkGlyph";

interface MonthCalendarProps {
  locale: Locale;
  label: string;
  weeks?: readonly number[];
  showMonth?: boolean;
  className?: string;
}

const columns = 7;
const firstMonday = Date.UTC(2026, 9, 5);
const dayInMs = 86_400_000;

export function MonthCalendar({ locale, label, weeks, showMonth = true, className }: MonthCalendarProps) {
  const { year, monthIndex, today, focusDay } = sampleMonth;
  const language = localeDetails[locale].htmlLang;
  const allWeeks = sampleWeeks();
  const shownWeeks = weeks === undefined ? allWeeks : allWeeks.filter((_, index) => weeks.includes(index));
  const shownCells = shownWeeks.flat();
  const focusIndex = shownCells.findIndex((cell) => cell.day === focusDay);
  const monthTitle = new Intl.DateTimeFormat(language, {
    month: "long",
    year: "numeric",
    timeZone: "UTC",
  }).format(new Date(Date.UTC(year, monthIndex, 1)));
  const weekday = new Intl.DateTimeFormat(language, { weekday: "short", timeZone: "UTC" });
  const weekdays = Array.from({ length: columns }, (_, index) =>
    weekday.format(new Date(firstMonday + index * dayInMs)),
  );
  const focusOrigin =
    focusIndex < 0
      ? undefined
      : ({
          "--focus-x": `${(((focusIndex % columns) + 0.5) / columns) * 100}%`,
          "--focus-y": `${((Math.floor(focusIndex / columns) + 0.5) / shownWeeks.length) * 100}%`,
        } as CSSProperties);

  return (
    <figure className={["calendar", className].filter(Boolean).join(" ")}>
      <VisuallyHidden>
        <figcaption>{label}</figcaption>
      </VisuallyHidden>
      <div className="calendar-head" aria-hidden>
        {showMonth && <span className="calendar-month">{monthTitle}</span>}
        <span className="calendar-weekdays">
          {weekdays.map((name) => (
            <span key={name}>{name}</span>
          ))}
        </span>
      </div>
      <div className="calendar-grid" style={focusOrigin} aria-hidden>
        {shownCells.map((cell) =>
          cell.day === null ? (
            <span key={cell.key} className="day" data-kind="blank" />
          ) : (
            <span
              key={cell.day}
              className="day"
              data-kind={cell.mark.kind}
              data-today={cell.day === today ? "" : undefined}
              data-focus={cell.day === focusDay ? "" : undefined}
            >
              <span className="day-number">{cell.day}</span>
              <DayMarkGlyph mark={cell.mark} />
            </span>
          ),
        )}
      </div>
    </figure>
  );
}
