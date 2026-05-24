jest.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string, params?: Record<string, string | number>) => {
      if (key === 'opportunities.composer.stepCounter')
        return `Step ${params?.current ?? 1} of ${params?.total ?? 3}`;
      return key;
    },
  }),
}));

jest.mock('expo-router', () => ({
  router: { replace: jest.fn(), push: jest.fn(), back: jest.fn() },
  useRouter: () => ({ replace: jest.fn(), push: jest.fn(), back: jest.fn() }),
}));

const mockCreate = jest.fn();
jest.mock('~/features/opportunities/hooks/useCreateOpportunity', () => ({
  useCreateOpportunity: () => ({
    mutateAsync: mockCreate,
    isPending: false,
  }),
}));

import { render, fireEvent, act } from '@testing-library/react-native';
import { OpportunityComposer } from '~/features/opportunities/components/OpportunityComposer';

describe('OpportunityComposer', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('blocks advancing from step 1 without picking a kind', () => {
    const { getByTestId, queryByTestId } = render(<OpportunityComposer />);
    fireEvent.press(getByTestId('opportunity-composer-next'));
    expect(getByTestId('opportunity-composer-kind-error')).toBeTruthy();
    // Still on step 1 — title field should not be mounted.
    expect(queryByTestId('opportunity-composer-title')).toBeNull();
  });

  it('surfaces inline title length error on step 2', () => {
    const { getByTestId, queryByTestId } = render(<OpportunityComposer />);

    // Pick a kind and advance to step 2.
    fireEvent.press(getByTestId('opportunity-composer-kind-hiring'));
    fireEvent.press(getByTestId('opportunity-composer-next'));
    expect(getByTestId('opportunity-composer-title')).toBeTruthy();

    // Type a too-short title.
    fireEvent.changeText(getByTestId('opportunity-composer-title'), 'no');
    fireEvent.changeText(
      getByTestId('opportunity-composer-body'),
      'Body is sufficiently long to pass the body length validation rule.'
    );
    fireEvent.press(getByTestId('opportunity-composer-next'));

    expect(getByTestId('opportunity-composer-title-error')).toBeTruthy();
    // Should NOT have advanced to step 3.
    expect(queryByTestId('opportunity-composer-submit')).toBeNull();
  });

  it('submits and calls the create mutation with the full input on the happy path', async () => {
    mockCreate.mockResolvedValueOnce('new-id');

    const { getByTestId } = render(<OpportunityComposer />);

    fireEvent.press(getByTestId('opportunity-composer-kind-hiring'));
    fireEvent.press(getByTestId('opportunity-composer-next'));

    fireEvent.changeText(
      getByTestId('opportunity-composer-title'),
      'Hiring a senior PM'
    );
    fireEvent.changeText(
      getByTestId('opportunity-composer-body'),
      'A longer description that satisfies the body length validation rules just fine.'
    );
    fireEvent.press(getByTestId('opportunity-composer-next'));

    fireEvent.changeText(getByTestId('opportunity-composer-tags'), 'pm, fintech');
    fireEvent.changeText(getByTestId('opportunity-composer-city'), 'Berlin');
    fireEvent.changeText(getByTestId('opportunity-composer-country'), 'DE');
    fireEvent(getByTestId('opportunity-composer-remote'), 'valueChange', true);

    await act(async () => {
      fireEvent.press(getByTestId('opportunity-composer-submit'));
    });

    expect(mockCreate).toHaveBeenCalledWith(
      expect.objectContaining({
        kind: 'hiring',
        title: 'Hiring a senior PM',
        body:
          'A longer description that satisfies the body length validation rules just fine.',
        tags: ['pm', 'fintech'],
        locationCity: 'Berlin',
        locationCountry: 'DE',
        remoteOk: true,
      })
    );
  });
});
