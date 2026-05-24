import Markdown from 'react-native-markdown-display';
import { Linking } from 'react-native';

const STYLES = {
  body: { color: '#9ca3af', fontSize: 14 },
  strong: { color: '#f9fafb', fontWeight: '700' as const },
  em: { fontStyle: 'italic' as const },
  link: { color: '#6366f1' },
};

// Only these schemes may be invoked from a user-authored bio. Anything else
// (intent:, javascript:, file:, app-private deeplinks like "bvisionryconnect:")
// is rejected silently — defends against linkified XSS in markdown bios.
const ALLOWED_SCHEMES = new Set(['http:', 'https:', 'mailto:']);

function isSafeUrl(url: string): boolean {
  try {
    // Use the WHATWG URL parser (polyfilled in RN via react-native-url-polyfill).
    const parsed = new URL(url);
    return ALLOWED_SCHEMES.has(parsed.protocol);
  } catch {
    // Fallback: parse the scheme by hand if URL constructor rejects it.
    const m = /^([a-z][a-z0-9+.-]*):/i.exec(url);
    if (!m) return false;
    return ALLOWED_SCHEMES.has(`${m[1]!.toLowerCase()}:`);
  }
}

async function openIfSafe(url: string): Promise<void> {
  if (!isSafeUrl(url)) {
    if (__DEV__) console.warn('[BioMarkdown] blocked unsafe URL:', url);
    return;
  }
  try {
    const can = await Linking.canOpenURL(url);
    if (!can) return;
    await Linking.openURL(url);
  } catch (e) {
    if (__DEV__) console.warn('[BioMarkdown] openURL failed:', e);
  }
}

export function BioMarkdown({ children }: { children: string }) {
  return (
    <Markdown
      style={STYLES as never}
      // react-native-markdown-display interprets the return value as "did the
      // consumer handle it?". We always return true so the library never falls
      // back to its built-in openUrl — which would skip our scheme allowlist.
      onLinkPress={(url) => {
        void openIfSafe(url);
        return true;
      }}
    >
      {children}
    </Markdown>
  );
}
