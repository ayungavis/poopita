import { site } from "../config/site";
import { type Locale, localeDetails, locales } from "../i18n/locales";
import type { PageMeta } from "../i18n/messages/types";
import { type Alternate, absoluteUrl, alternatesFor, type PageId, pathFor } from "./routes";

export interface Seo {
  title: string;
  description: string;
  htmlLang: string;
  canonical: string;
  alternates: readonly Alternate[];
  ogLocale: string;
  ogLocaleAlternates: readonly string[];
  imageUrl: string;
  imageAlt: string;
  appStoreId: number | undefined;
  jsonLd: string | undefined;
}

export interface SeoInput {
  locale: Locale;
  page: PageId;
  meta: PageMeta;
  imageAlt: string;
  appStoreId: number | undefined;
}

const imagePath = "/icons/app-icon-512.png";

export function seoFor({ locale, page, meta, imageAlt, appStoreId }: SeoInput): Seo {
  return {
    title: meta.title,
    description: meta.description,
    htmlLang: localeDetails[locale].htmlLang,
    canonical: absoluteUrl(pathFor(locale, page)),
    alternates: alternatesFor(page),
    ogLocale: localeDetails[locale].ogLocale,
    ogLocaleAlternates: locales
      .filter((other) => other !== locale)
      .map((other) => localeDetails[other].ogLocale),
    imageUrl: absoluteUrl(imagePath),
    imageAlt,
    appStoreId,
    jsonLd: page === "home" ? mobileApplicationJsonLd(locale, meta) : undefined,
  };
}

export function notFoundSeo(locale: Locale, meta: PageMeta): Seo {
  return {
    title: meta.title,
    description: meta.description,
    htmlLang: localeDetails[locale].htmlLang,
    canonical: absoluteUrl(`${pathFor(locale, "home")}404.html`),
    alternates: [],
    ogLocale: localeDetails[locale].ogLocale,
    ogLocaleAlternates: [],
    imageUrl: absoluteUrl(imagePath),
    imageAlt: site.name,
    appStoreId: undefined,
    jsonLd: undefined,
  };
}

function mobileApplicationJsonLd(locale: Locale, meta: PageMeta): string {
  return JSON.stringify({
    "@context": "https://schema.org",
    "@type": "MobileApplication",
    name: site.name,
    description: meta.description,
    url: absoluteUrl(pathFor(locale, "home")),
    inLanguage: locales,
    operatingSystem: "iOS",
    applicationCategory: "HealthApplication",
    offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
    author: { "@type": "Person", name: site.owner },
    license: `https://spdx.org/licenses/${site.licenseName}.html`,
  }).replaceAll("<", "\\u003c");
}
