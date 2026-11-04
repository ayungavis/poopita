import { Heading } from "@astryxdesign/core/Heading";
import { Text } from "@astryxdesign/core/Text";
import { VStack } from "@astryxdesign/core/VStack";
import type { ReactNode } from "react";

export type FeatureLayout = "split" | "split-reverse" | "stacked";

interface FeatureSectionProps {
  id: string;
  title: string;
  body: string;
  layout: FeatureLayout;
  children: ReactNode;
}

export function FeatureSection({ id, title, body, layout, children }: FeatureSectionProps) {
  const headingId = `${id}-title`;

  return (
    <section id={id} className="feature reveal" data-layout={layout} aria-labelledby={headingId}>
      <VStack gap={3} className="feature-copy">
        <Heading level={2} id={headingId} type="display-3" textWrap="balance">
          {title}
        </Heading>
        <Text as="p" type="large" color="secondary" textWrap="pretty">
          {body}
        </Text>
      </VStack>
      <div className="feature-visual">{children}</div>
    </section>
  );
}
