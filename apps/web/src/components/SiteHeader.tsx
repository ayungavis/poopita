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
  const other = localeDetails[otherLocale];

  return (
    <header className="site-header">
      <HStack as="nav" gap={4} justify="between" align="center" paddingBlock={3}>
        <Link href={pathFor(locale, "home")} label={common.homeLabel} color="primary">
          <HStack as="span" gap={2} align="center">
            <AppIcon alt="" size={32} />
            <Text type="large" weight="semibold">
              Poopita
            </Text>
          </HStack>
        </Link>
        <HStack as="ul" gap={4} align="center">
          <li className="site-header-page">
            <Link href={pathFor(locale, "privacy")} color="secondary">
              {common.nav.privacy}
            </Link>
          </li>
          <li className="site-header-page">
            <Link href={pathFor(locale, "support")} color="secondary">
              {common.nav.support}
            </Link>
          </li>
          <li>
            <button
              type="button"
              className="theme-toggle"
              aria-pressed="false"
              aria-label={common.darkTheme}
              title={common.darkTheme}
              hidden
            >
              <svg className="theme-icon" viewBox="0 0 24 24" aria-hidden="true">
                <circle className="theme-sun-core" cx="12" cy="12" r="4.5" />
                <path
                  className="theme-sun-rays"
                  d="M12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2M5.3 5.3l1.4 1.4M17.3 17.3l1.4 1.4M5.3 18.7l1.4-1.4M17.3 6.7l1.4-1.4"
                />
                <path className="theme-moon" d="M20 14.2A8 8 0 0 1 9.8 4a8 8 0 1 0 10.2 10.2Z" />
              </svg>
            </button>
          </li>
          <li>
            <a
              className="language-link"
              href={pathFor(otherLocale, page)}
              hrefLang={other.htmlLang}
              lang={other.htmlLang}
            >
              <svg className="language-globe" viewBox="0 0 24 24" aria-hidden="true">
                <circle cx="12" cy="12" r="9" />
                <path d="M3 12h18M12 3c2.5 2.6 3.8 5.6 3.8 9s-1.3 6.4-3.8 9c-2.5-2.6-3.8-5.6-3.8-9S9.5 5.6 12 3Z" />
              </svg>
              <span className="language-name">{other.label}</span>
              <span className="language-code" aria-hidden>
                {other.htmlLang.toUpperCase()}
              </span>
            </a>
          </li>
        </HStack>
      </HStack>
    </header>
  );
}
