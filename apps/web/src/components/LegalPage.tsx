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
      <section className="stage on-dark doc-stage" aria-labelledby="doc-title">
        <div className="doc-stage-grid">
          <VStack gap={4} align="start">
            <Heading level={1} id="doc-title" className="display display-hero" textWrap="balance">
              {document.title}
            </Heading>
            <Text as="p" type="supporting">
              {document.effective}
            </Text>
          </VStack>
          <VStack gap={3}>
            <Text as="p" type="supporting">
              {common.document.inShort}
            </Text>
            <ol className="doc-summary">
              {document.summary.map((line) => (
                <li key={line}>
                  <Text as="p" type="large" textWrap="pretty">
                    {line}
                  </Text>
                </li>
              ))}
            </ol>
          </VStack>
        </div>
      </section>
      <div className="doc">
        <nav className="doc-aside doc-toc" aria-labelledby="doc-toc-title">
          <Text as="p" type="supporting" id="doc-toc-title">
            {common.document.onThisPage}
          </Text>
          <ol>
            {document.sections.map((section) => (
              <li key={section.id}>
                <a href={`#${section.id}`}>{section.heading}</a>
              </li>
            ))}
          </ol>
        </nav>
        <article className="doc-body" aria-labelledby="doc-title">
          {document.sections.map((section) => (
            <LegalSection key={section.id} section={section} />
          ))}
        </article>
      </div>
    </SiteShell>
  );
}

function LegalSection({ section }: { section: DocumentSection }) {
  return (
    <section className="doc-section" aria-labelledby={section.id}>
      <Heading level={2} id={section.id} className="doc-heading">
        {section.heading}
      </Heading>
      <VStack gap={3}>
        {section.paragraphs.map((paragraph) => (
          <Text key={paragraph} as="p" color="secondary" textWrap="pretty">
            {paragraph}
          </Text>
        ))}
        {section.bullets !== undefined && (
          <ul className="doc-bullets">
            {section.bullets.map((bullet) => (
              <li key={bullet}>
                <Text color="secondary">{bullet}</Text>
              </li>
            ))}
          </ul>
        )}
        {section.links?.map((link) => (
          <Link key={link.href} href={link.href} isExternalLink>
            {link.label}
          </Link>
        ))}
      </VStack>
    </section>
  );
}
