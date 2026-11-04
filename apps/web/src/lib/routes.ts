import { site } from "../config/site";
import { defaultLocale, type Locale, locales } from "../i18n/locales";

export const pageIds = ["home", "privacy", "support", "terms"] as const;

export type PageId = (typeof pageIds)[number];

const pageSlugs: Record<PageId, string> = {
  home: "",
  privacy: "privacy/",
  support: "support/",
  terms: "terms/",
};

export interface Alternate {
  hreflang: string;
  href: string;
}

export function pathFor(locale: Locale, page: PageId): string {
  return `/${locale}/${pageSlugs[page]}`;
}

export function absoluteUrl(path: string): string {
  return new URL(path, site.origin).toString();
}

export function alternatesFor(page: PageId): Alternate[] {
  return [
    ...locales.map((locale) => ({ hreflang: locale, href: absoluteUrl(pathFor(locale, page)) })),
    { hreflang: "x-default", href: absoluteUrl(pathFor(defaultLocale, page)) },
  ];
}

export function localeStaticPaths() {
  return locales.map((locale) => ({ params: { locale } }));
}
