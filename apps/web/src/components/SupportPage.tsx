import { Heading } from "@astryxdesign/core/Heading";
import { Text } from "@astryxdesign/core/Text";
import { VStack } from "@astryxdesign/core/VStack";
import { site } from "../config/site";
import type { Locale } from "../i18n/locales";
import type { Messages } from "../i18n/messages/types";
import { PillLink } from "./PillLink";
import { QuestionList } from "./QuestionList";
import { SiteShell } from "./SiteShell";

interface SupportPageProps {
  locale: Locale;
  messages: Messages;
}

export function SupportPage({ locale, messages }: SupportPageProps) {
  const { common, support } = messages;

  return (
    <SiteShell locale={locale} page="support" common={common}>
      <section className="stage on-dark" aria-labelledby="support-title">
        <div className="stage-grid">
          <VStack gap={5} className="stage-copy" align="start">
            <Heading level={1} id="support-title" className="display display-hero" textWrap="balance">
              {support.title}
            </Heading>
            <Text as="p" type="large" color="secondary" textWrap="pretty">
              {support.lead}
            </Text>
            <VStack as="section" gap={3} align="start" aria-label={support.contact.title}>
              <PillLink href={`mailto:${site.supportEmail}`} label={site.supportEmail} tone="solid" />
              <Text as="p" type="supporting" textWrap="pretty">
                {support.contact.body} {support.contact.note}
              </Text>
            </VStack>
          </VStack>
          <div className="stage-visual stage-visual-after">
            <section className="paper report-slip" aria-labelledby="report-title">
              <VStack gap={2}>
                <Heading level={2} id="report-title" className="doc-heading">
                  {support.report.title}
                </Heading>
                <Text as="p" color="secondary" textWrap="pretty">
                  {support.report.body}
                </Text>
              </VStack>
              <ol className="report-list">
                {support.report.items.map((item) => (
                  <li key={item}>
                    <Text>{item}</Text>
                  </li>
                ))}
              </ol>
            </section>
          </div>
        </div>
      </section>
      <section className="doc chapter" aria-labelledby="faq-title">
        <div className="doc-aside">
          <Heading level={2} id="faq-title" className="display doc-title" textWrap="balance">
            {support.faqTitle}
          </Heading>
        </div>
        <div className="doc-body">
          <QuestionList questions={support.faq} />
        </div>
      </section>
    </SiteShell>
  );
}
