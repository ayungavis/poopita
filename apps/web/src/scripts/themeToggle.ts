type Theme = "light" | "dark";

const storageKey = "theme";
const root = document.documentElement;
const systemDark = window.matchMedia("(prefers-color-scheme: dark)");

function isTheme(value: unknown): value is Theme {
  return value === "light" || value === "dark";
}

function systemTheme(): Theme {
  return systemDark.matches ? "dark" : "light";
}

function activeTheme(): Theme {
  const chosen = root.dataset.theme;
  return isTheme(chosen) ? chosen : systemTheme();
}

function remember(theme: Theme | null) {
  try {
    if (theme === null) {
      localStorage.removeItem(storageKey);
    } else {
      localStorage.setItem(storageKey, theme);
    }
  } catch {
    return;
  }
}

function sync(buttons: NodeListOf<HTMLButtonElement>) {
  const isDark = activeTheme() === "dark";
  for (const button of buttons) {
    button.setAttribute("aria-pressed", String(isDark));
  }
  const background = getComputedStyle(document.body).backgroundColor;
  for (const meta of document.querySelectorAll<HTMLMetaElement>('meta[name="theme-color"]')) {
    meta.content = background;
  }
}

function apply(theme: Theme, buttons: NodeListOf<HTMLButtonElement>) {
  if (theme === systemTheme()) {
    delete root.dataset.theme;
    remember(null);
  } else {
    root.dataset.theme = theme;
    remember(theme);
  }
  sync(buttons);
}

function toggle(buttons: NodeListOf<HTMLButtonElement>) {
  const next: Theme = activeTheme() === "dark" ? "light" : "dark";
  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  if (reduceMotion || document.startViewTransition === undefined) {
    apply(next, buttons);
    return;
  }
  document.startViewTransition(() => apply(next, buttons));
}

export function setUpThemeToggle() {
  const buttons = document.querySelectorAll<HTMLButtonElement>(".theme-toggle");
  for (const button of buttons) {
    button.hidden = false;
    button.addEventListener("click", () => toggle(buttons));
  }
  systemDark.addEventListener("change", () => sync(buttons));
  sync(buttons);
}
