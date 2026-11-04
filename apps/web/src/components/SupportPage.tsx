import { Card } from "@astryxdesign/core/Card";
import { Heading } from "@astryxdesign/core/Heading";
import { Link } from "@astryxdesign/core/Link";
import { Text } from "@astryxdesign/core/Text";
import { VStack } from "@astryxdesign/core/VStack";
import { site } from "../config/site";
import type { Locale } from "../i18n/locales";
import type { Messages } from "../i18n/messages/types";
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
      <VStack gap={8} maxWidth={720}>
        <VStack gap={2}>
          <Heading level={1}>{support.title}</Heading>
          <Text as="p" type="large" color="secondary">
            {support.lead}
          </Text>
        </VStack>
        <Card padding={6}>
          <VStack as="section" gap={2} aria-label={support.contact.title}>
            <Link href={`mailto:${site.supportEmail}`} size="lg" weight="semibold">
              {site.supportEmail}
            </Link>
            <Text>{support.contact.body}</Text>
            <Text type="supporting">{support.contact.note}</Text>
          </VStack>
        </Card>
        <VStack as="section" gap={4} aria-labelledby="faq-title">
          <Heading level={2} id="faq-title">
            {support.faqTitle}
          </Heading>
          <QuestionList questions={support.faq} />
        </VStack>
        <VStack as="section" gap={2} aria-labelledby="report-title">
          <Heading level={2} id="report-title">
            {support.report.title}
          </Heading>
          <Text as="p" color="secondary">
            {support.report.body}
          </Text>
          <VStack as="ul" gap={1} style={{ listStyle: "disc", paddingInlineStart: "var(--spacing-5)" }}>
            {support.report.items.map((item) => (
              <li key={item}>
                <Text color="secondary">{item}</Text>
              </li>
            ))}
          </VStack>
        </VStack>
      </VStack>
    </SiteShell>
  );
}
