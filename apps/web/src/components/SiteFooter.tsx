import { Text } from "@astryxdesign/core/Text";
import { site } from "../config/site";
import type { Locale } from "../i18n/locales";
import type { Messages } from "../i18n/messages/types";
import { pathFor } from "../lib/routes";
import { AppIcon } from "./AppIcon";

interface SiteFooterProps {
  locale: Locale;
  common: Messages["common"];
}

export function SiteFooter({ locale, common }: SiteFooterProps) {
  const { footer, nav } = common;
  const links = [
    { label: nav.privacy, href: pathFor(locale, "privacy"), leavesSite: false },
    { label: nav.terms, href: pathFor(locale, "terms"), leavesSite: false },
    { label: nav.support, href: pathFor(locale, "support"), leavesSite: false },
    { label: footer.source, href: site.sourceUrl, leavesSite: true },
  ];

  return (
    <footer className="site-footer on-dark">
      <div className="footer-tab">
        <a className="footer-brand" href={pathFor(locale, "home")} aria-label={common.homeLabel}>
          <AppIcon alt="" size={36} />
          <span>Poopita</span>
        </a>
      </div>
      <div className="footer-grid">
        <p className="footer-cell footer-tagline">{footer.tagline}</p>
        <div className="footer-cell footer-contact">
          <Text as="p" type="supporting">
            {footer.writeTo}
          </Text>
          <a className="footer-email" href={`mailto:${site.supportEmail}`}>
            {site.supportEmail}
          </a>
          <Text as="p" type="supporting">
            {footer.madeBy}{" "}
            <a className="footer-owner" href={site.ownerUrl}>
              {site.owner}
            </a>
          </Text>
        </div>
        <ul className="footer-nav">
          {links.map((link) => (
            <li key={link.href}>
              <a className="footer-cell footer-link" href={link.href}>
                {link.label}
                <span className="footer-arrow" aria-hidden>
                  {link.leavesSite ? "↗" : "→"}
                </span>
              </a>
            </li>
          ))}
        </ul>
        <div className="footer-cell footer-legal">
          <Text as="p" type="supporting">
            {footer.copyright} · {footer.openSource}
          </Text>
          <p className="footer-fine">{footer.trademark}</p>
        </div>
      </div>
      <span className="footer-wordmark" aria-hidden>
        Poopita
      </span>
    </footer>
  );
}
