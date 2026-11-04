import { site } from "../../config/site";
import type { Messages } from "./types";

const effective = "Effective 4 November 2026";

export const en: Messages = {
  common: {
    skipToContent: "Skip to content",
    switchLanguage: "Bahasa Indonesia",
    homeLabel: "Poopita home",
    nav: { privacy: "Privacy", support: "Support", terms: "Terms" },
    document: { inShort: "In short", onThisPage: "On this page" },
    darkTheme: "Dark theme",
    store: {
      download: "Download on the App Store",
      comingSoon: "Coming soon to the App Store",
    },
    notFound: {
      title: "Page not found",
      body: "This page doesn't exist, or it moved.",
      home: "Go to the home page",
      calendarLabel: "A week in Poopita. Two days were never recorded, so they show as unknown.",
      note: "Striped days weren't recorded, so Poopita shows them as unknown, never as zero. This page is one of those.",
    },
    footer: {
      contact: "Contact",
      openSource: `Open source under ${site.licenseName}`,
      trademark: "Apple, the Apple logo, iPhone and App Store are trademarks of Apple Inc.",
      copyright: `© 2026 ${site.owner}`,
    },
  },
  landing: {
    meta: {
      title: "Poopita — Private poop & bowel diary for iPhone",
      description:
        "Log each bowel movement in seconds, see your routine take shape, and keep it private. No account, no ads, and your diary stays on your iPhone.",
    },
    hero: {
      title: "A private diary for your bowel routine.",
      lead: "Log each poop in seconds. In a few weeks you'll see your usual, and when it changes. It all stays on your iPhone.",
      trust: ["No account", "Stays on your iPhone", "No ads or tracking"],
      iconAlt: "The Poopita app icon",
      calendarLabel:
        "A sample October in Poopita: most days carry a drawn stool type, three are confirmed no-poop days, four were never recorded and stay hatched, and today is still open.",
      seeHow: "See how it works",
    },
    log: {
      title: "Log in seconds",
      body: "Pick the Bristol type, how much, how hard it felt, and whether you saw blood. That's a complete log. Add color, time on the toilet or a short note when you want.",
      sample: {
        time: "Tuesday 14 October, 07:42",
        fields: [
          { label: "Type", value: "4 · smooth and soft" },
          { label: "Amount", value: "Medium" },
          { label: "Effort", value: "Easy" },
          { label: "Blood", value: "No blood" },
        ],
      },
    },
    days: {
      title: "Unknown is never zero",
      body: "On a day you don't go, say so with one tap. A day you didn't record stays unknown, so your history never pretends to know more than you told it.",
      comparison: {
        plainLabel: "A simple counter",
        poopitaLabel: "Poopita",
        rows: [
          { situation: "A day you forgot to log", plain: "Counts as 0", poopita: "Stays unknown" },
          {
            situation: "A day you didn't go",
            plain: "Looks like forgetting",
            poopita: "Confirmed with one tap",
          },
          { situation: "Today, before you go", plain: "Already 0", poopita: "None so far" },
        ],
      },
    },
    insights: {
      title: "See what's usual for you",
      body: "How often, how consistent and how comfortable, by week, month or year, and what changed from your usual. No scores, no streaks. When you need it, export a PDF for your doctor.",
      average: "1.2",
      averageLabel: "logs a day, on days you logged",
      consistency: { title: "Consistency", hard: "Hard 1–2", usual: "Usual 3–5", loose: "Loose 6–7" },
    },
    reminders: {
      title: "One quiet nudge",
      body: "A daily check-in only on days you haven't logged yet. The notification just says \"Quick check-in\", so nobody reading over your shoulder learns what it's for.",
      notificationTitle: "Quick check-in",
      notificationBody: "Nothing logged today yet. Tap to log, or hold for more.",
    },
    privacy: {
      title: "Your poop, your business.",
      lead: "Poopita was built so that nobody but you ever sees your diary. Not us, not advertisers, not a cloud.",
      items: [
        {
          title: "Stays on this iPhone",
          body: "Your diary is stored on your iPhone. There is no server and no sync, and nothing is uploaded.",
        },
        { title: "No account", body: "Nothing to sign up for, no email, no password." },
        {
          title: "Locked when you want",
          body: "Lock Poopita with Face ID, Touch ID or your passcode, and hide it in the app switcher.",
        },
        {
          title: "Only anonymous crash reports",
          body: "If the app crashes, it may send a technical report with no diary content and nothing that identifies you.",
        },
      ],
      policyLink: "Read the privacy policy",
      sourceLink: "Check the source code",
    },
    limits: {
      title: "Honest limits",
      items: [
        "Poopita is a diary, not a medical device. It doesn't diagnose or treat anything. If something worries you, talk to a doctor.",
        "There is no backup yet. Deleting the app deletes the diary. Moving to a new iPhone with Quick Start or an iPhone backup brings it along.",
      ],
    },
    faq: {
      title: "Questions",
      items: [
        { question: "Is it free?", answer: ["Yes. No ads, no subscription and no in-app purchases."] },
        {
          question: "Is it private?",
          answer: [
            "Your diary never leaves your iPhone. The only thing the app ever sends is an anonymous crash report, without any diary content.",
          ],
        },
        { question: "Do I need an account?", answer: ["No. Open the app and start logging."] },
        {
          question: "What is the Bristol scale?",
          answer: [
            "A chart that sorts stool into seven types by shape, from hard lumps (type 1) to watery (type 7). Pick the closest one; it doesn't need to be exact.",
          ],
        },
        {
          question: "What happens if I lose my phone?",
          answer: [
            "Without an iPhone backup, the diary is gone with it. We never have a copy. An encrypted Poopita backup is planned.",
          ],
        },
      ],
      more: "More answers on the support page",
    },
    closing: {
      statement: "A diary that only knows what you tell it, and keeps it to itself.",
    },
  },
  privacy: {
    meta: {
      title: "Privacy policy — Poopita",
      description:
        "Poopita keeps your diary on your iPhone. Read what stays on your device, the anonymous crash reports the app may send, and your rights.",
    },
    title: "Privacy policy",
    effective,
    summary: [
      "Your diary stays on your iPhone. We never see it.",
      "There is no account, no advertising and no tracking.",
      "The app may send anonymous crash reports so we can fix bugs. They contain no diary content.",
    ],
    sections: [
      {
        id: "who-we-are",
        heading: "Who we are",
        paragraphs: [
          `Poopita is made by ${site.owner}, an individual developer in Indonesia ("we"). For anything about this policy, write to ${site.supportEmail}.`,
        ],
      },
      {
        id: "on-your-device",
        heading: "What stays on your device",
        paragraphs: [
          "Everything you put into Poopita stays on your iPhone: logs, no-poop check-ins, notes, reminders, app lock and appearance settings. It is not sent to us, to iCloud or to anyone else, and we can't see, recover or delete it for you.",
          "Exports (the CSV file and the PDF for your doctor) are created on your iPhone and go only where you choose to share them.",
        ],
      },
      {
        id: "what-we-receive",
        heading: "What we receive",
        paragraphs: [
          "When Poopita hits a technical failure, it may send a crash report. A report contains an error code, technical stack information, the app version and the time. It contains no diary content, no name, no email address and no device identifier, and IP addresses are not stored.",
          "We use crash reports only to find and fix bugs. Our legal basis is our legitimate interest in keeping the app working.",
        ],
      },
      {
        id: "processor",
        heading: "Who processes it",
        paragraphs: [
          "Crash reports are processed for us by Sentry (Functional Software, Inc., USA) under its data processing agreement. Data may be processed in the United States; transfers rely on the EU-U.S. Data Privacy Framework and standard contractual clauses.",
        ],
        links: [
          { label: "Sentry data processing agreement", href: site.sentryDpaUrl },
          { label: "Sentry sub-processors", href: site.sentrySubprocessorsUrl },
        ],
      },
      {
        id: "retention",
        heading: "How long it's kept",
        paragraphs: [
          `Crash reports are deleted after ${site.crashReportRetentionDays} days. Data on your iPhone lasts until you delete it or the app.`,
        ],
      },
      {
        id: "what-we-dont-do",
        heading: "What we don't do",
        bullets: [
          "No account and no sign-in.",
          "No advertising and no tracking across apps or websites.",
          "No selling or sharing of data.",
          "No use of health information for marketing.",
        ],
        paragraphs: [],
      },
      {
        id: "choices",
        heading: "Your choices and rights",
        paragraphs: [
          "Delete a single entry from its edit screen, or everything from Settings › Your data › Delete all history. Deleting the app removes all of its data from your iPhone.",
          "Depending on where you live (for example under the GDPR or Indonesia's Personal Data Protection Law), you can ask to access, correct or delete personal data, object to processing, and complain to your data protection authority. Because crash reports are not linked to a person, we usually can't match a request to a report, but write to us and we'll help as far as we can.",
        ],
      },
      {
        id: "security",
        heading: "Security",
        paragraphs: [
          "Your diary is protected by iOS data protection, and you can add Face ID, Touch ID or passcode lock and hide the app in the app switcher. If a breach ever affected you, we would tell you and the authorities as the law requires, which in Indonesia is within 3 × 24 hours.",
        ],
      },
      {
        id: "children",
        heading: "Children",
        paragraphs: ["Poopita is not directed at children under 13."],
      },
      {
        id: "website",
        heading: "This website",
        paragraphs: [
          "This website sets no cookies and runs no analytics. It is hosted on Cloudflare, which processes standard request logs to deliver and protect the site.",
        ],
        links: [{ label: "Cloudflare privacy policy", href: site.cloudflarePrivacyUrl }],
      },
      {
        id: "changes",
        heading: "Changes",
        paragraphs: [
          "We'll post any change here with a new effective date, and mention material changes in the app's release notes.",
        ],
      },
      {
        id: "contact",
        heading: "Contact",
        paragraphs: [
          `Write to ${site.supportEmail}. This policy is published in English and Bahasa Indonesia; for users in Indonesia, the Indonesian version prevails.`,
        ],
      },
    ],
  },
  terms: {
    meta: {
      title: "Terms of use — Poopita",
      description:
        "Poopita is licensed under Apple's Standard EULA. It is a personal diary, not a medical device.",
    },
    title: "Terms of use",
    effective,
    summary: [
      "Apple's Standard License Agreement governs the app.",
      "Poopita is a diary, not a medical device.",
      "Your diary lives on your iPhone, so keeping it safe is up to you.",
    ],
    sections: [
      {
        id: "license",
        heading: "License",
        paragraphs: [
          "The Poopita app is licensed to you under Apple's Licensed Application End User License Agreement (the Standard EULA), which governs your use of the app. These terms add to it and don't replace it.",
        ],
        links: [{ label: "Apple Standard EULA", href: site.appleEulaUrl }],
      },
      {
        id: "not-medical",
        heading: "Not medical advice",
        paragraphs: [
          "Poopita is a personal diary. It is not a medical device and does not diagnose, treat or prevent any condition. Insights are general information about what you logged. Talk to a doctor about anything that worries you, especially blood, black or pale stool, or a change that lasts. In an emergency, call your local emergency number.",
        ],
      },
      {
        id: "your-data",
        heading: "Your data",
        paragraphs: [
          "Your diary is stored only on your iPhone. There is no Poopita backup yet, so keep your iPhone backed up if you don't want to lose it. We can't recover a diary for you.",
        ],
      },
      {
        id: "source",
        heading: "Source code and trademarks",
        paragraphs: [
          `The source code is available under the ${site.licenseName} license. The Poopita name, icon and mascot are not covered by that license and may not be used for other apps.`,
          "Apple, the Apple logo, iPhone and App Store are trademarks of Apple Inc., registered in the U.S. and other countries and regions.",
        ],
        links: [{ label: "Source code", href: site.sourceUrl }],
      },
      {
        id: "website",
        heading: "This website",
        paragraphs: ["The content of this website is general information and may change without notice."],
      },
      {
        id: "contact",
        heading: "Contact",
        paragraphs: [
          `Write to ${site.supportEmail}. These terms are published in English and Bahasa Indonesia; for users in Indonesia, the Indonesian version prevails.`,
        ],
      },
    ],
  },
  support: {
    meta: {
      title: "Support — Poopita",
      description:
        "Get help with Poopita: app lock, a new phone, deleting data, reminders, language and the Bristol scale.",
    },
    title: "Support",
    lead: "Something not working, or an idea to share? Here's how to reach us, and answers to the common questions.",
    contact: {
      title: "Contact",
      body: "We usually reply within two working days.",
      note: "Please don't send photos or details about your health. We don't need them to help.",
    },
    faqTitle: "Common questions",
    faq: [
      {
        question: "How do I lock Poopita?",
        answer: [
          "Go to Settings › Privacy and turn on the lock. Poopita then asks for Face ID, Touch ID or your passcode when you open it. It stays open if you come back within 1 minute.",
          "If Face ID doesn't recognize you, use your iPhone passcode.",
        ],
      },
      {
        question: "I'm moving to a new iPhone. Will my diary come along?",
        answer: [
          "Yes, if you move with Quick Start or restore from an iPhone backup. There is no separate Poopita backup yet, so without an iPhone backup a lost phone means a lost diary. We never have a copy.",
        ],
      },
      {
        question: "How do I delete my data?",
        answer: [
          "Delete one entry from its edit screen. To delete everything, go to Settings › Your data › Delete all history. You can save a copy first with Export all data.",
          "Deleting the app also removes its data. There is nothing to delete on our side.",
        ],
      },
      {
        question: "My reminders don't arrive.",
        answer: [
          "Check iOS Settings › Notifications › Poopita, any Focus that might silence it, and whether Scheduled Summary holds it back. Then check the time and days in Poopita › Settings › Reminders.",
          'If "Skip if I\'ve already logged" is on, a day with a log or check-in gets no reminder.',
        ],
      },
      {
        question: "How do I change the language?",
        answer: [
          "Go to Poopita › Settings › Language. The app closes and opens again in the new language; your diary isn't affected.",
        ],
      },
      {
        question: "What is the Bristol scale?",
        answer: [
          "It sorts stool into seven types by shape. Pick the closest one; it doesn't need to be exact.",
          "1: separate hard lumps, like nuts. 2: sausage-shaped but lumpy. 3: like a sausage with cracks. 4: like a sausage or snake, smooth and soft. 5: soft blobs with clear-cut edges. 6: fluffy, mushy pieces. 7: watery, no solid pieces.",
        ],
      },
      {
        question: "Why does a day show as unknown instead of zero?",
        answer: [
          "Poopita only counts what you tell it. A day with no log and no check-in might have had a bowel movement you didn't record, so it stays unknown. Confirm a no-poop day with one tap to make it count.",
        ],
      },
      {
        question: "Can Poopita tell me if something is wrong?",
        answer: [
          "No. Poopita is a diary, not a medical device. It points out what's worth a doctor's look, such as blood or black, red or pale stool, but only a doctor can tell you what it means. Use Export for your doctor to bring your history along.",
        ],
      },
    ],
    report: {
      title: "Reporting a bug",
      body: "Tell us:",
      items: [
        "Your iOS version and the Poopita version (Settings, at the bottom).",
        "What you did, what you expected, and what happened instead.",
      ],
    },
  },
};
