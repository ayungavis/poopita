import { type DoodleName, doodlePaths } from "./doodlePaths";

interface DoodleProps {
  name: DoodleName;
  label?: string;
}

export function Doodle({ name, label }: DoodleProps) {
  const accessibility = label === undefined ? { "aria-hidden": true } : { role: "img", "aria-label": label };

  return (
    <svg
      className="doodle"
      viewBox="0 0 48 32"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.9}
      strokeLinecap="round"
      strokeLinejoin="round"
      focusable="false"
      {...accessibility}
    >
      {doodlePaths[name].map((path) => (
        <path key={path} d={path} />
      ))}
    </svg>
  );
}
