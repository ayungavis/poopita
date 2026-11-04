import { Text } from "@astryxdesign/core/Text";
import { site } from "../config/site";
import type { Locale } from "../i18n/locales";
import type { Messages } from "../i18n/messages/types";
import { pathFor } from "../lib/routes";

interface SiteFooterProps {
  locale: Locale;
  common: Messages["common"];
}

export function SiteFooter({ locale, common }: SiteFooterProps) {
  const links = [
    { label: common.nav.privacy, href: pathFor(locale, "privacy") },
    { label: common.nav.terms, href: pathFor(locale, "terms") },
    { label: common.nav.support, href: pathFor(locale, "support") },
    { label: common.footer.contact, href: `mailto:${site.supportEmail}` },
    { label: common.footer.openSource, href: site.sourceUrl },
  ];

  return (
    <footer className="footer-card on-dark">
      <ul className="footer-links">
        {links.map((link) => (
          <li key={link.href}>
            <a href={link.href}>{link.label}</a>
          </li>
        ))}
      </ul>
      <div className="footer-base">
        <span className="footer-wordmark" aria-hidden>
          Poopita
        </span>
        <div className="footer-meta">
          <Text type="supporting">{common.footer.copyright}</Text>
          <Text type="supporting">{common.footer.trademark}</Text>
        </div>
      </div>
    </footer>
  );
}
