import type { Locale } from "./locales";
import { en } from "./messages/en";
import { id } from "./messages/id";
import type { Messages } from "./messages/types";

const catalog: Record<Locale, Messages> = { en, id };

export function messagesFor(locale: Locale): Messages {
  return catalog[locale];
}
