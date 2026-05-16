import { render } from '@testing-library/react-native';
import { BioMarkdown } from '~/features/profile/components/BioMarkdown';

describe('BioMarkdown', () => {
  it('renders plain text', () => {
    const { getByText } = render(<BioMarkdown>Hello world</BioMarkdown>);
    expect(getByText('Hello world')).toBeTruthy();
  });

  it('renders bold text', () => {
    const { getByText } = render(<BioMarkdown>Building **AI** tools</BioMarkdown>);
    // The text `AI` should be rendered as a child node with strong styling
    expect(getByText('AI')).toBeTruthy();
  });

  it('renders link text', () => {
    const { getByText } = render(<BioMarkdown>Visit [my site](https://example.com)</BioMarkdown>);
    expect(getByText('my site')).toBeTruthy();
  });
});
