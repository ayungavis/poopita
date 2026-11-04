import { Heading } from "@astryxdesign/core/Heading";
import { HStack } from "@astryxdesign/core/HStack";
import { Text } from "@astryxdesign/core/Text";
import { VStack } from "@astryxdesign/core/VStack";
import type { Locale } from "../../i18n/locales";
import type { Messages } from "../../i18n/messages/types";
import { MonthCalendar } from "../calendar/MonthCalendar";
import { PillLink } from "../PillLink";
import { StoreButton } from "../StoreButton";

interface HeroProps {
  locale: Locale;
  hero: Messages["landing"]["hero"];
  store: Messages["common"]["store"];
  appStoreUrl: string | null;
}

export function Hero({ locale, hero, store, appStoreUrl }: HeroProps) {
  return (
    <section className="stage on-dark" aria-labelledby="hero-title">
      <div className="stage-grid">
        <VStack gap={5} className="stage-copy">
          <Heading level={1} id="hero-title" className="display display-hero" textWrap="balance">
            {hero.title}
          </Heading>
          <Text as="p" type="large" color="secondary" textWrap="pretty">
            {hero.lead}
          </Text>
          <HStack gap={3} wrap="wrap" align="center">
            <StoreButton url={appStoreUrl} labels={store} />
            <PillLink href="#log" label={hero.seeHow} tone="soft" />
          </HStack>
          <ul className="stage-tags">
            {hero.trust.map((tag) => (
              <li key={tag} className="tag">
                + {tag}
              </li>
            ))}
          </ul>
        </VStack>
        <div className="stage-visual hero-calendar">
          <MonthCalendar locale={locale} label={hero.calendarLabel} />
        </div>
      </div>
    </section>
  );
}
