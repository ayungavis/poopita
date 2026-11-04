import { Button } from "@astryxdesign/core/Button";
import { Heading } from "@astryxdesign/core/Heading";
import { HStack } from "@astryxdesign/core/HStack";
import { Text } from "@astryxdesign/core/Text";
import { VStack } from "@astryxdesign/core/VStack";
import type { Locale } from "../../i18n/locales";
import type { Messages } from "../../i18n/messages/types";
import { MonthCalendar } from "../calendar/MonthCalendar";
import { StoreButton } from "../StoreButton";

interface HeroProps {
  locale: Locale;
  hero: Messages["landing"]["hero"];
  store: Messages["common"]["store"];
  appStoreUrl: string | null;
}

export function Hero({ locale, hero, store, appStoreUrl }: HeroProps) {
  return (
    <section className="hero-stage" aria-labelledby="hero-title">
      <VStack gap={5} align="center" className="hero-copy">
        <Heading level={1} id="hero-title" type="display-1" justify="center" textWrap="balance">
          {hero.title}
        </Heading>
        <Text as="p" type="large" color="secondary" justify="center" textWrap="balance">
          {hero.lead}
        </Text>
        <HStack gap={3} wrap="wrap" justify="center" align="center">
          <StoreButton url={appStoreUrl} labels={store} />
          <Button href="#log" label={hero.seeHow} variant="secondary" size="lg" />
        </HStack>
        <Text type="supporting" justify="center">
          {hero.trust.join(" · ")}
        </Text>
      </VStack>
      <div className="hero-calendar">
        <MonthCalendar locale={locale} label={hero.calendarLabel} />
        <Text as="p" type="supporting" justify="center">
          {hero.calendarCaption}
        </Text>
      </div>
    </section>
  );
}
