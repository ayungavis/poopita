import { Theme } from "@astryxdesign/core/theme";
import { Heading } from "@astryxdesign/core/Heading";
import { Link } from "@astryxdesign/core/Link";
import { Text } from "@astryxdesign/core/Text";
import { VStack } from "@astryxdesign/core/VStack";
import { type Locale, localeDetails, locales } from "../i18n/locales";
import { messagesFor } from "../i18n";
import { pathFor } from "../lib/routes";
import { poopitaTheme } from "../themes/poopita";
import { Doodle } from "./Doodle";

export function NotFoundPage() {
  return (
    <Theme theme={poopitaTheme}>
      <VStack as="main" gap={10} align="center" paddingBlock={10} paddingInline={5}>
        <Doodle name="pile" />
        {locales.map((locale) => (
          <NotFoundMessage key={locale} locale={locale} />
        ))}
      </VStack>
    </Theme>
  );
}

function NotFoundMessage({ locale }: { locale: Locale }) {
  const { notFound } = messagesFor(locale).common;
  const HeadingLevel = locale === locales[0] ? 1 : 2;

  return (
    <section lang={localeDetails[locale].htmlLang}>
      <VStack gap={2} align="center">
        <Heading level={HeadingLevel} justify="center">
          {notFound.title}
        </Heading>
        <Text as="p" color="secondary" justify="center">
          {notFound.body}
        </Text>
        <Link href={pathFor(locale, "home")}>{notFound.home}</Link>
      </VStack>
    </section>
  );
}
