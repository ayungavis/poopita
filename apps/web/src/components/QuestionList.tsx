import { Text } from "@astryxdesign/core/Text";
import { VStack } from "@astryxdesign/core/VStack";
import type { Question } from "../i18n/messages/types";

interface QuestionListProps {
  questions: readonly Question[];
}

export function QuestionList({ questions }: QuestionListProps) {
  return (
    <VStack>
      {questions.map((item) => (
        <details key={item.question} className="faq-item">
          <summary>
            <Text type="large" weight="semibold">
              {item.question}
            </Text>
          </summary>
          <VStack gap={2} paddingBlockStart={3}>
            {item.answer.map((paragraph) => (
              <Text key={paragraph} as="p" color="secondary">
                {paragraph}
              </Text>
            ))}
          </VStack>
        </details>
      ))}
    </VStack>
  );
}
