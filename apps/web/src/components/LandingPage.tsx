import type { Locale } from "../i18n/locales";
import type { Messages } from "../i18n/messages/types";
import { ClosingSection, FaqSection, LimitsSection } from "./landing/ClosingSections";
import { Hero } from "./landing/Hero";
import { PrivacySection } from "./landing/PrivacySection";
import { DaysSection, InsightsSection, LogSection, RemindersSection } from "./landing/StorySections";
import { WhySection } from "./landing/WhySection";
import { SiteShell } from "./SiteShell";

interface LandingPageProps {
  locale: Locale;
  messages: Messages;
  appStoreUrl: string | null;
}

export function LandingPage({ locale, messages, appStoreUrl }: LandingPageProps) {
  const { common, landing } = messages;

  return (
    <SiteShell locale={locale} page="home" common={common}>
      <Hero locale={locale} hero={landing.hero} store={common.store} appStoreUrl={appStoreUrl} />
      <LogSection log={landing.log} />
      <WhySection why={landing.why} />
      <DaysSection locale={locale} days={landing.days} />
      <InsightsSection insights={landing.insights} />
      <RemindersSection reminders={landing.reminders} />
      <PrivacySection locale={locale} privacy={landing.privacy} />
      <LimitsSection limits={landing.limits} />
      <FaqSection locale={locale} faq={landing.faq} />
      <ClosingSection closing={landing.closing} store={common.store} appStoreUrl={appStoreUrl} />
    </SiteShell>
  );
}
