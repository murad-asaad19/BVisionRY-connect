import { render } from '@testing-library/react-native';
import { Text } from 'react-native';
import { QueryState } from '~/components/ui/QueryState';

const baseQuery = {
  isLoading: false,
  isError: false,
  error: null,
  data: undefined as unknown,
  refetch: jest.fn(),
};

describe('QueryState', () => {
  it('renders loading fallback while loading', () => {
    const { getByTestId } = render(
      <QueryState query={{ ...baseQuery, isLoading: true }}>
        {() => <Text>content</Text>}
      </QueryState>
    );
    expect(getByTestId('query-state-loading')).toBeTruthy();
  });

  it('renders error state with message on error', () => {
    const { getByTestId, getByText } = render(
      <QueryState query={{ ...baseQuery, isError: true, error: new Error('boom') }}>
        {() => <Text>content</Text>}
      </QueryState>
    );
    expect(getByTestId('query-state-error')).toBeTruthy();
    expect(getByText('boom')).toBeTruthy();
  });

  it('renders children with data', () => {
    const { getByText } = render(
      <QueryState query={{ ...baseQuery, data: { name: 'Alice' } }}>
        {(d) => <Text>{(d as { name: string }).name}</Text>}
      </QueryState>
    );
    expect(getByText('Alice')).toBeTruthy();
  });

  it('renders empty fallback when isEmpty returns true', () => {
    const { getByText } = render(
      <QueryState
        query={{ ...baseQuery, data: [] }}
        isEmpty={(d) => (d as unknown[]).length === 0}
        emptyFallback={<Text>nothing here</Text>}
      >
        {() => <Text>content</Text>}
      </QueryState>
    );
    expect(getByText('nothing here')).toBeTruthy();
  });
});
