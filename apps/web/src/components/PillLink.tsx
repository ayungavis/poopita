interface PillLinkProps {
  href: string;
  label: string;
  tone: "solid" | "soft";
}

export function PillLink({ href, label, tone }: PillLinkProps) {
  const leavesSite = /^(https?:|mailto:)/.test(href);

  return (
    <a className="pill" data-tone={tone} href={href}>
      {label}
      {leavesSite && (
        <span className="pill-arrow" aria-hidden>
          ↗
        </span>
      )}
    </a>
  );
}
