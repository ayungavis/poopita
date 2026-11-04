import { HStack } from "@astryxdesign/core/HStack";
import { Link } from "@astryxdesign/core/Link";
import { Text } from "@astryxdesign/core/Text";
import { type Locale, localeDetails, locales } from "../i18n/locales";
import type { Messages } from "../i18n/messages/types";
import { type PageId, pathFor } from "../lib/routes";
import { AppIcon } from "./AppIcon";

interface SiteHeaderProps {
  locale: Locale;
  page: PageId;
  common: Messages["common"];
}

export function SiteHeader({ locale, page, common }: SiteHeaderProps) {
  const otherLocale = locales.find((candidate) => candidate !== locale) ?? locale;

  return (
    <HStack as="nav" gap={4} justify="between" align="center" wrap="wrap" paddingBlock={3}>
      <Link href={pathFor(locale, "home")} label={common.homeLabel} color="primary">
        <HStack as="span" gap={2} align="center">
          <AppIcon alt="" size={32} />
          <Text type="large" weight="semibold">
            Poopita
          </Text>
        </HStack>
      </Link>
      <HStack as="ul" gap={4} align="center" wrap="wrap">
        <li>
          <Link href={pathFor(locale, "privacy")} color="secondary">
            {common.nav.privacy}
          </Link>
        </li>
        <li>
          <Link href={pathFor(locale, "support")} color="secondary">
            {common.nav.support}
          </Link>
        </li>
        <li lang={localeDetails[otherLocale].htmlLang}>
          <Link href={pathFor(otherLocale, page)} label={common.switchLanguage} color="secondary">
            {localeDetails[otherLocale].htmlLang.toUpperCase()}
          </Link>
        </li>
      </HStack>
    </HStack>
  );
}
