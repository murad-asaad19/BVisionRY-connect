import AsyncStorage from '@react-native-async-storage/async-storage';
import { useOnboardingDraft } from '~/features/onboarding/store/useOnboardingDraft';

jest.mock('@react-native-async-storage/async-storage', () =>
  require('@react-native-async-storage/async-storage/jest/async-storage-mock')
);

describe('useOnboardingDraft', () => {
  beforeEach(async () => {
    await AsyncStorage.clear();
    useOnboardingDraft.setState(useOnboardingDraft.getInitialState());
  });

  it('starts with empty draft', () => {
    const { draft } = useOnboardingDraft.getState();
    expect(draft).toEqual({});
  });

  it('setField updates a single key', () => {
    useOnboardingDraft.getState().setField('name', 'Ahmad');
    expect(useOnboardingDraft.getState().draft.name).toBe('Ahmad');
  });

  it('reset clears the draft', () => {
    useOnboardingDraft.getState().setField('name', 'Ahmad');
    useOnboardingDraft.getState().reset();
    expect(useOnboardingDraft.getState().draft).toEqual({});
  });
});
