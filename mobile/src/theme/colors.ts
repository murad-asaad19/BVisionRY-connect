// IMPORTANT: keep these values in sync with the `@theme` block in `global.css`.
// global.css is the source for Tailwind utilities (Tailwind v4 is CSS-first);
// this file is the source for direct TS/JSX usage (e.g., TextInput placeholderTextColor).
export const colors = {
  bg: {
    primary: '#0B1220',
    secondary: '#111827',
    elevated: '#1F2937',
  },
  text: {
    primary: '#F9FAFB',
    secondary: '#9CA3AF',
    muted: '#6B7280',
  },
  accent: {
    primary: '#6366F1',
    hover: '#4F46E5',
  },
  border: {
    subtle: '#1F2937',
    strong: '#374151',
  },
  semantic: {
    success: '#10B981',
    warning: '#F59E0B',
    danger: '#EF4444',
  },
} as const;
