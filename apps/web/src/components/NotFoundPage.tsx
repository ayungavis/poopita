import { Heading } from "@astryxdesign/core/Heading";
import { HStack } from "@astryxdesign/core/HStack";
import { Text } from "@astryxdesign/core/Text";
import { VStack } from "@astryxdesign/core/VStack";
import type { Locale } from "../i18n/locales";
import type { Messages } from "../i18n/messages/types";
import { pathFor } from "../lib/routes";
import { MonthCalendar } from "./calendar/MonthCalendar";
import { PillLink } from "./PillLink";
import { SiteShell } from "./SiteShell";

interface NotFoundPageProps {
  locale: Locale;
  common: Messages["common"];
}

const weekWithUnknownDays = [2];

export function NotFoundPage({ locale, common }: NotFoundPageProps) {
  const { notFound } = common;

  return (
    <SiteShell locale={locale} page="home" common={common}>
      <section className="stage on-dark not-found" aria-labelledby="not-found-title">
        <div className="stage-grid">
          <VStack gap={5} className="stage-copy" align="start">
            <Heading level={1} id="not-found-title" className="display display-hero" textWrap="balance">
              {notFound.title}
            </Heading>
            <Text as="p" type="large" color="secondary" textWrap="pretty">
              {notFound.body}
            </Text>
            <HStack gap={3} wrap="wrap" align="center">
              <PillLink href={pathFor(locale, "home")} label={notFound.home} tone="solid" />
              <PillLink href={pathFor(locale, "support")} label={common.nav.support} tone="soft" />
            </HStack>
          </VStack>
          <VStack gap={3} className="stage-visual stage-visual-after not-found-visual">
            <MonthCalendar locale={locale} label={notFound.calendarLabel} weeks={weekWithUnknownDays} />
            <Text as="p" type="supporting" textWrap="pretty">
              {notFound.note}
            </Text>
          </VStack>
        </div>
      </section>
    </SiteShell>
  );
}
