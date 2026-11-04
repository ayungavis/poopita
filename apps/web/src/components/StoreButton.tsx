import { Button } from "@astryxdesign/core/Button";
import type { Messages } from "../i18n/messages/types";

interface StoreButtonProps {
  url: string | null;
  labels: Messages["common"]["store"];
}

export function StoreButton({ url, labels }: StoreButtonProps) {
  if (url === null) {
    return <span className="store-soon">{labels.comingSoon}</span>;
  }
  return <Button href={url} label={labels.download} variant="primary" size="lg" />;
}
