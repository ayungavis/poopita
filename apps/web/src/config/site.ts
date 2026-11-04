export const site = {
  name: "Poopita",
  origin: "https://poopita.ayungavis.com",
  owner: "Wahyu Adi Kurniawan",
  ownerUrl: "https://ayungavis.com",
  supportEmail: "wahyu@ayungavis.com",
  sourceUrl: "https://github.com/ayungavis/poopita",
  licenseName: "Apache-2.0",
  effectiveDate: "2026-11-04",
  crashReportRetentionDays: 30,
  appleEulaUrl: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/",
  sentryDpaUrl: "https://sentry.io/legal/dpa/",
  sentrySubprocessorsUrl: "https://sentry.io/legal/subprocessors/",
  cloudflarePrivacyUrl: "https://www.cloudflare.com/privacypolicy/",
} as const;

export function appStoreUrl(appStoreId: number | undefined): string | null {
  return appStoreId === undefined ? null : `https://apps.apple.com/app/id${appStoreId}`;
}
