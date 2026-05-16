import Markdown from 'react-native-markdown-display';
import { Linking } from 'react-native';

const STYLES = {
  body: { color: '#9ca3af', fontSize: 14 },
  strong: { color: '#f9fafb', fontWeight: '700' as const },
  em: { fontStyle: 'italic' as const },
  link: { color: '#6366f1' },
};

export function BioMarkdown({ children }: { children: string }) {
  return (
    <Markdown
      style={STYLES as never}
      onLinkPress={(url) => {
        Linking.openURL(url).catch(console.warn);
        return false;
      }}
    >
      {children}
    </Markdown>
  );
}
