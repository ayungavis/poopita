import { Text } from "@astryxdesign/core/Text";
import { VStack } from "@astryxdesign/core/VStack";
import type { DayMark } from "../../content/sampleMonth";
import type { Locale } from "../../i18n/locales";
import type { Messages } from "../../i18n/messages/types";
import { AppIcon } from "../AppIcon";
import { DayMarkGlyph } from "../calendar/DayMarkGlyph";
import { MonthCalendar } from "../calendar/MonthCalendar";
import { WeekRhythm } from "../calendar/WeekRhythm";
import { FeatureSection } from "./FeatureSection";

type Landing = Messages["landing"];

export function LogSection({ log }: { log: Landing["log"] }) {
  return (
    <FeatureSection id="log" title={log.title} body={log.body} layout="split">
      <div className="log-slip">
        <span className="day day-large" data-kind="logged">
          <span className="day-number">14</span>
          <DayMarkGlyph mark={{ kind: "logged", types: [4] }} />
        </span>
        <VStack gap={3}>
          <Text type="supporting">{log.sample.time}</Text>
          <dl className="log-fields">
            {log.sample.fields.map((field) => (
              <div key={field.label}>
                <dt>{field.label}</dt>
                <dd>{field.value}</dd>
              </div>
            ))}
          </dl>
          <Text type="supporting">{log.optional}</Text>
        </VStack>
      </div>
    </FeatureSection>
  );
}

const legendMarks: readonly DayMark[] = [
  { kind: "logged", types: [4] },
  { kind: "none" },
  { kind: "partial" },
  { kind: "unknown" },
];

export function DaysSection({ locale, days }: { locale: Locale; days: Landing["days"] }) {
  return (
    <FeatureSection id="days" title={days.title} body={days.body} layout="stacked">
      <VStack gap={6}>
        <MonthCalendar
          locale={locale}
          label={days.body}
          weeks={[3, 4]}
          showMonth={false}
          className="calendar-weeks"
        />
        <ul className="legend">
          {days.marks.map((item, index) => {
            const mark = legendMarks[index] ?? { kind: "unknown" };
            return (
              <li key={item.title} className="legend-item">
                <span className="legend-swatch day" data-kind={mark.kind} aria-hidden>
                  <DayMarkGlyph mark={mark} />
                </span>
                <VStack gap={0.5}>
                  <Text weight="semibold">{item.title}</Text>
                  <Text type="supporting">{item.body}</Text>
                </VStack>
              </li>
            );
          })}
        </ul>
      </VStack>
    </FeatureSection>
  );
}

export function InsightsSection({ insights }: { insights: Landing["insights"] }) {
  const { consistency } = insights;

  return (
    <FeatureSection id="insights" title={insights.title} body={insights.body} layout="split-reverse">
      <div className="insight-sheet">
        <WeekRhythm label={insights.body} />
        <VStack gap={5}>
          <VStack gap={1}>
            <span className="insight-number">{insights.average}</span>
            <Text color="secondary">{insights.averageLabel}</Text>
          </VStack>
          <VStack gap={2}>
            <Text weight="semibold">{consistency.title}</Text>
            <div className="share-bar" aria-hidden>
              <span className="share-hard" style={{ flexGrow: 10 }} />
              <span className="share-usual" style={{ flexGrow: 78 }} />
              <span className="share-loose" style={{ flexGrow: 12 }} />
            </div>
            <div className="share-legend">
              <Text type="supporting">{consistency.hard}</Text>
              <Text type="supporting">{consistency.usual}</Text>
              <Text type="supporting">{consistency.loose}</Text>
            </div>
          </VStack>
        </VStack>
      </div>
    </FeatureSection>
  );
}

export function RemindersSection({ reminders }: { reminders: Landing["reminders"] }) {
  return (
    <FeatureSection id="reminders" title={reminders.title} body={reminders.body} layout="stacked">
      <div className="reminder-scene">
        <span className="day day-large" data-kind="partial" data-today="" aria-hidden>
          <span className="day-number">28</span>
          <DayMarkGlyph mark={{ kind: "partial" }} />
        </span>
        <div className="notification">
          <AppIcon alt="" size={40} />
          <VStack gap={0.5}>
            <Text weight="semibold">{reminders.notificationTitle}</Text>
            <Text type="supporting">{reminders.notificationBody}</Text>
          </VStack>
        </div>
      </div>
    </FeatureSection>
  );
}
