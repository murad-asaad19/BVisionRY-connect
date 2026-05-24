// Shared semantic intent palette used by Banner, Pill, and the danger-tone Button variants.
// Branded variants (navy/gold/outline/apple/solid) remain hard-coded in their components.

export type Intent = 'neutral' | 'info' | 'success' | 'warning' | 'danger';

export type IntentClasses = {
  bg: string;
  text: string;
  border: string;
};

const INTENT_CLASSES: Record<Intent, IntentClasses> = {
  neutral: { bg: 'bg-slate-100', text: 'text-muted', border: 'border border-border' },
  info: { bg: 'bg-info-bg', text: 'text-info-text', border: 'border border-info-border' },
  success: {
    bg: 'bg-success-bg',
    text: 'text-success-text',
    border: 'border border-success-border',
  },
  warning: {
    bg: 'bg-warning-bg',
    text: 'text-warning-text',
    border: 'border border-warning-border',
  },
  danger: {
    bg: 'bg-danger-bg',
    text: 'text-danger-text',
    border: 'border border-danger-border',
  },
};

export function intentClasses(intent: Intent): IntentClasses {
  return INTENT_CLASSES[intent];
}
