export interface PageMeta {
  title: string;
  description: string;
}

export interface TextLink {
  label: string;
  href: string;
}

export interface Item {
  title: string;
  body: string;
}

export interface LabeledValue {
  label: string;
  value: string;
}

export interface Question {
  question: string;
  answer: readonly string[];
}

export interface DocumentSection {
  id: string;
  heading: string;
  paragraphs: readonly string[];
  bullets?: readonly string[];
  links?: readonly TextLink[];
}

export interface LegalDocument {
  meta: PageMeta;
  title: string;
  effective: string;
  summary: readonly string[];
  sections: readonly DocumentSection[];
}

export interface Messages {
  common: {
    skipToContent: string;
    switchLanguage: string;
    homeLabel: string;
    nav: { privacy: string; support: string; terms: string };
    store: { download: string; comingSoon: string };
    notFound: { title: string; body: string; home: string };
    footer: {
      contact: string;
      openSource: string;
      trademark: string;
      copyright: string;
    };
  };
  landing: {
    meta: PageMeta;
    hero: {
      title: string;
      lead: string;
      trust: readonly string[];
      iconAlt: string;
      calendarLabel: string;
      seeHow: string;
    };
    log: {
      title: string;
      body: string;
      sample: { time: string; fields: readonly LabeledValue[] };
    };
    days: {
      title: string;
      body: string;
      comparison: {
        plainLabel: string;
        poopitaLabel: string;
        rows: readonly { situation: string; plain: string; poopita: string }[];
      };
    };
    insights: {
      title: string;
      body: string;
      average: string;
      averageLabel: string;
      consistency: { title: string; hard: string; usual: string; loose: string };
    };
    reminders: {
      title: string;
      body: string;
      notificationTitle: string;
      notificationBody: string;
    };
    privacy: {
      title: string;
      lead: string;
      items: readonly Item[];
      policyLink: string;
      sourceLink: string;
    };
    limits: { title: string; items: readonly string[] };
    faq: { title: string; items: readonly Question[]; more: string };
    closing: { statement: string };
  };
  privacy: LegalDocument;
  terms: LegalDocument;
  support: {
    meta: PageMeta;
    title: string;
    lead: string;
    contact: { title: string; body: string; note: string };
    faqTitle: string;
    faq: readonly Question[];
    report: { title: string; body: string; items: readonly string[] };
  };
}
