export const locales = ["en", "id"] as const;

export type Locale = (typeof locales)[number];

export const defaultLocale: Locale = "en";

export const localeDetails: Record<Locale, { htmlLang: string; ogLocale: string; label: string }> = {
  en: { htmlLang: "en", ogLocale: "en_US", label: "English" },
  id: { htmlLang: "id", ogLocale: "id_ID", label: "Bahasa Indonesia" },
};

export function isLocale(value: unknown): value is Locale {
  return typeof value === "string" && (locales as readonly string[]).includes(value);
}

export function parseLocale(value: unknown): Locale {
  if (!isLocale(value)) {
    throw new Error(`Unsupported locale "${String(value)}". Expected one of: ${locales.join(", ")}.`);
  }
  return value;
}
