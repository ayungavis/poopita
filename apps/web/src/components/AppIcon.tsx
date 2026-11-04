interface AppIconProps {
  alt: string;
  size: number;
}

const variants = [
  { tone: "light", src: "/icons/app-icon-512.png" },
  { tone: "dark", src: "/icons/app-icon-dark-512.png" },
] as const;

export function AppIcon({ alt, size }: AppIconProps) {
  return (
    <span className="app-icon-pair">
      {variants.map((variant) => (
        <img
          key={variant.tone}
          className="app-icon"
          data-tone={variant.tone}
          src={variant.src}
          alt={variant.tone === "light" ? alt : ""}
          width={size}
          height={size}
          decoding="async"
          loading="lazy"
          style={{ inlineSize: size }}
        />
      ))}
    </span>
  );
}
