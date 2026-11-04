import { Heading } from "@astryxdesign/core/Heading";
import { HStack } from "@astryxdesign/core/HStack";
import { Text } from "@astryxdesign/core/Text";
import { VStack } from "@astryxdesign/core/VStack";
import { site } from "../../config/site";
import type { Locale } from "../../i18n/locales";
import type { Messages } from "../../i18n/messages/types";
import { pathFor } from "../../lib/routes";

interface PrivacySectionProps {
  locale: Locale;
  privacy: Messages["landing"]["privacy"];
}

export function PrivacySection({ locale, privacy }: PrivacySectionProps) {
  return (
    <section id="privacy" className="band reveal" aria-labelledby="privacy-title">
      <VStack gap={8} className="band-inner">
        <VStack gap={3} maxWidth={720}>
          <Heading level={2} id="privacy-title" type="display-2">
            {privacy.title}
          </Heading>
          <Text as="p" type="large">
            {privacy.lead}
          </Text>
        </VStack>
        <ul className="band-list">
          {privacy.items.map((item) => (
            <li key={item.title}>
              <VStack gap={1}>
                <Text weight="semibold">{item.title}</Text>
                <Text color="secondary">{item.body}</Text>
              </VStack>
            </li>
          ))}
        </ul>
        <HStack gap={5} wrap="wrap">
          <a className="band-link" href={pathFor(locale, "privacy")}>
            {privacy.policyLink}
          </a>
          <a className="band-link" href={site.sourceUrl}>
            {privacy.sourceLink}
          </a>
        </HStack>
      </VStack>
    </section>
  );
}
