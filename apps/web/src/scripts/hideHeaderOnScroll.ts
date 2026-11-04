export function hideHeaderOnScroll() {
  const header = document.querySelector<HTMLElement>(".site-header");
  if (header === null) {
    return;
  }

  const threshold = 6;
  let lastY = window.scrollY;
  let pending = false;

  const update = () => {
    pending = false;
    const y = Math.max(window.scrollY, 0);
    const delta = y - lastY;
    if (Math.abs(delta) < threshold) {
      return;
    }
    const hidden = delta > 0 && y > header.offsetHeight && !header.contains(document.activeElement);
    header.toggleAttribute("data-hidden", hidden);
    lastY = y;
  };

  window.addEventListener(
    "scroll",
    () => {
      if (!pending) {
        pending = true;
        requestAnimationFrame(update);
      }
    },
    { passive: true },
  );

  header.addEventListener("focusin", () => header.removeAttribute("data-hidden"));
}
