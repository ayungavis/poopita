interface AppIconProps {
  alt: string;
  size: number;
  isPriority?: boolean;
}

export function AppIcon({ alt, size, isPriority = false }: AppIconProps) {
  return (
    <picture>
      <source srcSet="/icons/app-icon-dark-512.png" media="(prefers-color-scheme: dark)" />
      <img
        className="app-icon"
        src="/icons/app-icon-512.png"
        alt={alt}
        width={size}
        height={size}
        decoding="async"
        fetchPriority={isPriority ? "high" : "auto"}
        loading={isPriority ? "eager" : "lazy"}
        style={{ inlineSize: size }}
      />
    </picture>
  );
}
