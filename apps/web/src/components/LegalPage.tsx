import { Card } from "@astryxdesign/core/Card";
import { Heading } from "@astryxdesign/core/Heading";
import { Link } from "@astryxdesign/core/Link";
import { Text } from "@astryxdesign/core/Text";
import { VStack } from "@astryxdesign/core/VStack";
import type { Locale } from "../i18n/locales";
import type { DocumentSection, LegalDocument, Messages } from "../i18n/messages/types";
import type { PageId } from "../lib/routes";
import { SiteShell } from "./SiteShell";

interface LegalPageProps {
  locale: Locale;
  page: Extract<PageId, "privacy" | "terms">;
  common: Messages["common"];
  document: LegalDocument;
}

export function LegalPage({ locale, page, common, document }: LegalPageProps) {
  return (
    <SiteShell locale={locale} page={page} common={common}>
      <VStack as="article" gap={8} maxWidth={720}>
        <VStack gap={2}>
          <Heading level={1}>{document.title}</Heading>
          <Text type="supporting">{document.effective}</Text>
        </VStack>
        <Card variant="muted">
          <VStack as="ul" gap={2}>
            {document.summary.map((line) => (
              <li key={line}>
                <Text weight="medium">{line}</Text>
              </li>
            ))}
          </VStack>
        </Card>
        {document.sections.map((section) => (
          <LegalSection key={section.id} section={section} />
        ))}
      </VStack>
    </SiteShell>
  );
}

function LegalSection({ section }: { section: DocumentSection }) {
  return (
    <VStack as="section" gap={3} aria-labelledby={section.id}>
      <Heading level={2} id={section.id}>
        {section.heading}
      </Heading>
      {section.paragraphs.map((paragraph) => (
        <Text key={paragraph} as="p" color="secondary" textWrap="pretty">
          {paragraph}
        </Text>
      ))}
      {section.bullets !== undefined && (
        <VStack as="ul" gap={1} style={{ listStyle: "disc", paddingInlineStart: "var(--spacing-5)" }}>
          {section.bullets.map((bullet) => (
            <li key={bullet}>
              <Text color="secondary">{bullet}</Text>
            </li>
          ))}
        </VStack>
      )}
      {section.links?.map((link) => (
        <Link key={link.href} href={link.href} isExternalLink>
          {link.label}
        </Link>
      ))}
    </VStack>
  );
}
