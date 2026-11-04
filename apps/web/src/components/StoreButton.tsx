import type { Messages } from "../i18n/messages/types";
import { PillLink } from "./PillLink";

interface StoreButtonProps {
  url: string | null;
  labels: Messages["common"]["store"];
}

export function StoreButton({ url, labels }: StoreButtonProps) {
  if (url === null) {
    return <span className="pill store-soon">{labels.comingSoon}</span>;
  }
  return <PillLink href={url} label={labels.download} tone="solid" />;
}
