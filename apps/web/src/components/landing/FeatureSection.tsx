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
  tone?: "light" | "dark";
  scale?: "section" | "statement";
  children: ReactNode;
}

export function FeatureSection({
  id,
  title,
  body,
  layout,
  tone = "light",
  scale = "section",
  children,
}: FeatureSectionProps) {
  const headingId = `${id}-title`;

  return (
    <section
      id={id}
      className={tone === "dark" ? "chapter band on-dark reveal" : "chapter reveal"}
      aria-labelledby={headingId}
    >
      <div className="feature" data-layout={layout}>
        <VStack gap={4} className="feature-copy">
          <Heading
            level={2}
            id={headingId}
            className={scale === "statement" ? "display display-statement" : "display display-section"}
            textWrap="balance"
          >
            {title}
          </Heading>
          <Text as="p" type="large" color="secondary" textWrap="pretty">
            {body}
          </Text>
        </VStack>
        <div className="feature-visual">{children}</div>
      </div>
    </section>
  );
}
