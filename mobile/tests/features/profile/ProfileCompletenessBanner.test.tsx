import { render } from '@testing-library/react-native';
import { ProfileCompletenessBanner } from '~/features/profile/components/ProfileCompletenessBanner';
import type { Database } from '~/lib/supabase/types.gen';

jest.mock('expo-router', () => ({ router: { push: jest.fn() } }));

jest.mock('react-i18next', () => ({
  useTranslation: () => ({
    t: (key: string, vars?: Record<string, unknown>) => {
      if (key === 'profile.missingPhoto') return 'photo';
      if (key === 'profile.missingHeadline') return 'headline';
      if (key === 'profile.missingBio') return 'bio';
      if (key === 'profile.completenessTitle') return `Your profile is ${vars?.percent}% complete`;
      if (key === 'profile.completenessMissing') return `Missing: ${vars?.fields}`;
      if (key === 'profile.completenessAction') return 'Complete';
      return key;
    },
  }),
}));

type ProfileRow = Database['public']['Tables']['profiles']['Row'];

function makeProfile(overrides: Partial<ProfileRow> = {}): ProfileRow {
  return {
    id: 'u1',
    email: 'a@b.com',
    name: 'Alice',
    handle: 'alice',
    bio: null,
    headline: null,
    photo_url: null,
    city: null,
    country: null,
    goal_text: null,
    goal_type: null,
    goal_updated_at: null,
    primary_role: null,
    roles: [],
    notify_intro: true,
    notify_meeting: true,
    notify_message: true,
    onboarded: true,
    verified_at: null,
    verified_github_id: null,
    verified_github_username: null,
    private_mode: false,
    read_receipts_enabled: false,
    public_investor_page: false,
    suspended_at: null,
    created_at: '2026-05-16T00:00:00Z',
    updated_at: '2026-05-16T00:00:00Z',
    ...overrides,
  };
}

describe('ProfileCompletenessBanner', () => {
  it('hides when all optional fields are present', () => {
    const profile = makeProfile({
      photo_url: 'https://example.com/x.jpg',
      headline: 'Builder',
      bio: 'Hi',
    });
    const { queryByTestId } = render(<ProfileCompletenessBanner profile={profile} />);
    expect(queryByTestId('profile-completeness')).toBeNull();
  });

  it('renders when at least one optional field is missing', () => {
    const profile = makeProfile({ headline: 'Builder', bio: 'Hi' });
    const { getByTestId } = render(<ProfileCompletenessBanner profile={profile} />);
    expect(getByTestId('profile-completeness')).toBeTruthy();
  });

  it('shows correct percentage when 1/3 missing', () => {
    const profile = makeProfile({ headline: 'Builder', bio: 'Hi' });
    const { getByText } = render(<ProfileCompletenessBanner profile={profile} />);
    // 1 missing of 3 -> 67%
    expect(getByText(/67% complete/)).toBeTruthy();
  });

  it('shows 0% when all three missing', () => {
    const profile = makeProfile();
    const { getByText } = render(<ProfileCompletenessBanner profile={profile} />);
    expect(getByText(/0% complete/)).toBeTruthy();
  });

  it('lists missing fields', () => {
    const profile = makeProfile({ photo_url: 'https://example.com/x.jpg' });
    const { getByText } = render(<ProfileCompletenessBanner profile={profile} />);
    expect(getByText(/Missing:.*headline.*bio/)).toBeTruthy();
  });
});
