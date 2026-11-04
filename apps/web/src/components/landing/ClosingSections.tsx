import { Heading } from "@astryxdesign/core/Heading";
import { Link } from "@astryxdesign/core/Link";
import { Text } from "@astryxdesign/core/Text";
import { VStack } from "@astryxdesign/core/VStack";
import type { Locale } from "../../i18n/locales";
import type { Messages } from "../../i18n/messages/types";
import { pathFor } from "../../lib/routes";
import { MonthCalendar } from "../calendar/MonthCalendar";
import { QuestionList } from "../QuestionList";
import { StoreButton } from "../StoreButton";

export function LimitsSection({ limits }: { limits: Messages["landing"]["limits"] }) {
  return (
    <section className="prose reveal" aria-labelledby="limits-title">
      <VStack gap={3}>
        <Heading level={2} id="limits-title">
          {limits.title}
        </Heading>
        {limits.items.map((item) => (
          <Text key={item} as="p" type="large" color="secondary" textWrap="pretty">
            {item}
          </Text>
        ))}
      </VStack>
    </section>
  );
}

export function FaqSection({ locale, faq }: { locale: Locale; faq: Messages["landing"]["faq"] }) {
  return (
    <section className="prose reveal" aria-labelledby="faq-title">
      <VStack gap={4}>
        <Heading level={2} id="faq-title">
          {faq.title}
        </Heading>
        <QuestionList questions={faq.items} />
        <Link href={pathFor(locale, "support")}>{faq.more}</Link>
      </VStack>
    </section>
  );
}

interface ClosingSectionProps {
  locale: Locale;
  closing: Messages["landing"]["closing"];
  store: Messages["common"]["store"];
  calendarLabel: string;
  appStoreUrl: string | null;
}

export function ClosingSection({ locale, closing, store, calendarLabel, appStoreUrl }: ClosingSectionProps) {
  return (
    <section className="closing reveal" aria-labelledby="closing-title">
      <VStack gap={4} align="center">
        <MonthCalendar locale={locale} label={calendarLabel} className="calendar-compact" />
        <Heading level={2} id="closing-title" type="display-3" justify="center">
          {closing.title}
        </Heading>
        <Text as="p" type="large" color="secondary" justify="center">
          {closing.body}
        </Text>
        <StoreButton url={appStoreUrl} labels={store} />
      </VStack>
    </section>
  );
}
