import { Theme } from "@astryxdesign/core/theme";
import { VStack } from "@astryxdesign/core/VStack";
import type { ReactNode } from "react";
import type { Locale } from "../i18n/locales";
import type { Messages } from "../i18n/messages/types";
import type { PageId } from "../lib/routes";
import { poopitaTheme } from "../themes/poopita";
import { SiteFooter } from "./SiteFooter";
import { SiteHeader } from "./SiteHeader";

interface SiteShellProps {
  locale: Locale;
  page: PageId;
  common: Messages["common"];
  children: ReactNode;
}

const contentWidth = 1040;

export function SiteShell({ locale, page, common, children }: SiteShellProps) {
  return (
    <Theme theme={poopitaTheme}>
      <a className="skip-link" href="#main">
        {common.skipToContent}
      </a>
      <VStack maxWidth={contentWidth} paddingInline={5} style={{ marginInline: "auto" }}>
        <SiteHeader locale={locale} page={page} common={common} />
        <VStack as="main" id="main" gap={10} paddingBlock={6}>
          {children}
        </VStack>
        <SiteFooter locale={locale} common={common} />
      </VStack>
    </Theme>
  );
}
