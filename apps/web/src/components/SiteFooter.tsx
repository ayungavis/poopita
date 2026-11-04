import { Divider } from "@astryxdesign/core/Divider";
import { HStack } from "@astryxdesign/core/HStack";
import { Link } from "@astryxdesign/core/Link";
import { Text } from "@astryxdesign/core/Text";
import { VStack } from "@astryxdesign/core/VStack";
import { site } from "../config/site";
import type { Locale } from "../i18n/locales";
import type { Messages } from "../i18n/messages/types";
import { pathFor } from "../lib/routes";

interface SiteFooterProps {
  locale: Locale;
  common: Messages["common"];
}

export function SiteFooter({ locale, common }: SiteFooterProps) {
  return (
    <VStack as="footer" gap={4} paddingBlock={8}>
      <Divider />
      <HStack gap={4} wrap="wrap">
        <Link href={pathFor(locale, "privacy")} color="secondary">
          {common.nav.privacy}
        </Link>
        <Link href={pathFor(locale, "terms")} color="secondary">
          {common.nav.terms}
        </Link>
        <Link href={pathFor(locale, "support")} color="secondary">
          {common.nav.support}
        </Link>
        <Link href={`mailto:${site.supportEmail}`} color="secondary">
          {common.footer.contact}
        </Link>
        <Link href={site.sourceUrl} color="secondary">
          {common.footer.openSource}
        </Link>
      </HStack>
      <VStack gap={1}>
        <Text type="supporting">{common.footer.copyright}</Text>
        <Text type="supporting">{common.footer.trademark}</Text>
      </VStack>
    </VStack>
  );
}
