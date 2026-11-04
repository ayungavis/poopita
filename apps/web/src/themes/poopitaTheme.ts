import { defineTheme } from "@astryxdesign/core/theme";
import { neutralTheme } from "@astryxdesign/theme-neutral";

const fontFamily = "DM Sans Variable";
const fallbacks = "system-ui, -apple-system, sans-serif";

export const poopitaTheme = defineTheme({
  name: "poopita",
  extends: neutralTheme,
  typography: {
    scale: { base: 16, ratio: 1.25 },
    body: { family: fontFamily, fallbacks },
    heading: { family: fontFamily, fallbacks },
  },
  radius: { base: 12, multiplier: 1 },
  tokens: {
    "--color-background-body": ["#F6F7F8", "#15191C"],
    "--color-background-surface": ["#FFFFFF", "#1F252A"],
    "--color-background-card": ["#FFFFFF", "#1F252A"],
    "--color-background-muted": ["#E4EAEE", "#2A3238"],
    "--color-text-primary": ["#2A353C", "#E9EDF0"],
    "--color-text-secondary": ["#60717C", "#9AA8B1"],
    "--color-text-accent": ["#183C59", "#B9CDDF"],
    "--color-accent": ["#2A353C", "#E9EDF0"],
    "--color-on-accent": ["#FFFFFF", "#15191C"],
    "--color-border": ["#DDE3E7", "#2E363C"],
    "--color-text-error": ["#9C5429", "#E39A6C"],
  },
  localTokens: {
    "--poopita-rust": ["#9C5429", "#E39A6C"],
    "--poopita-partial": ["#A07A2E", "#D4B26A"],
    "--poopita-marker": ["#6E8DA8", "#7E9BB4"],
    "--poopita-entry": ["#B9CDDF", "#2F4B63"],
    "--poopita-track": ["#E4EAEE", "#2A3238"],
    "--poopita-hairline": ["#DDE3E7", "#2E363C"],
    "--poopita-band": ["#2A353C", "#1F252A"],
    "--poopita-on-band": ["#FFFFFF", "#E9EDF0"],
    "--poopita-on-band-secondary": ["#C9D3DA", "#9AA8B1"],
  },
  components: {
    button: {
      base: { borderRadius: "9999px" },
    },
  },
});
