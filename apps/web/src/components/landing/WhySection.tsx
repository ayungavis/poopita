import { Heading } from "@astryxdesign/core/Heading";
import { Text } from "@astryxdesign/core/Text";
import type { Messages } from "../../i18n/messages/types";

export function WhySection({ why }: { why: Messages["landing"]["why"] }) {
  return (
    <section id="why" className="why chapter reveal" aria-labelledby="why-title">
      <Heading level={2} id="why-title" className="display display-section" textWrap="balance">
        {why.title}
      </Heading>
      <ol className="why-list">
        {why.items.map((item) => (
          <li key={item.title}>
            <Text as="p" className="why-item-title" textWrap="balance">
              {item.title}
            </Text>
            <Text as="p" color="secondary" textWrap="pretty">
              {item.body}
            </Text>
          </li>
        ))}
      </ol>
      <Text as="p" type="supporting" textWrap="balance" className="why-note">
        {why.note}
      </Text>
    </section>
  );
}
