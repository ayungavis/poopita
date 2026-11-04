import { Heading } from "@astryxdesign/core/Heading";
import { Link } from "@astryxdesign/core/Link";
import { Text } from "@astryxdesign/core/Text";
import { VStack } from "@astryxdesign/core/VStack";
import type { Locale } from "../../i18n/locales";
import type { Messages } from "../../i18n/messages/types";
import { pathFor } from "../../lib/routes";
import { QuestionList } from "../QuestionList";
import { StoreButton } from "../StoreButton";

export function LimitsSection({ limits }: { limits: Messages["landing"]["limits"] }) {
  return (
    <section className="limits chapter reveal" aria-labelledby="limits-title">
      <Heading level={2} id="limits-title" className="display display-section">
        {limits.title}
      </Heading>
      <ol className="limits-list">
        {limits.items.map((item) => (
          <li key={item}>
            <Text as="p" type="large" textWrap="pretty">
              {item}
            </Text>
          </li>
        ))}
      </ol>
    </section>
  );
}

export function FaqSection({ locale, faq }: { locale: Locale; faq: Messages["landing"]["faq"] }) {
  return (
    <section className="prose reveal" aria-labelledby="faq-title">
      <VStack gap={4}>
        <Heading level={2} id="faq-title">
          {faq.title}
        </Heading>
        <QuestionList questions={faq.items} />
        <Link href={pathFor(locale, "support")}>{faq.more}</Link>
      </VStack>
    </section>
  );
}

interface ClosingSectionProps {
  closing: Messages["landing"]["closing"];
  store: Messages["common"]["store"];
  appStoreUrl: string | null;
}

export function ClosingSection({ closing, store, appStoreUrl }: ClosingSectionProps) {
  return (
    <section className="manifesto reveal" aria-labelledby="closing-title">
      <div className="manifesto-line">
        <Heading level={2} id="closing-title" className="display display-manifesto" display="inline">
          {closing.statement}
        </Heading>{" "}
        <StoreButton url={appStoreUrl} labels={store} />
      </div>
    </section>
  );
}
