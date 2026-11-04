interface PillLinkProps {
  href: string;
  label: string;
  tone: "solid" | "soft";
}

export function PillLink({ href, label, tone }: PillLinkProps) {
  return (
    <a className="pill" data-tone={tone} href={href}>
      {label}
      <span className="pill-arrow" aria-hidden>
        ↗
      </span>
    </a>
  );
}
