jest.mock('~/lib/supabase/client', () => ({
  supabase: { rpc: jest.fn() },
}));

import { supabase } from '~/lib/supabase/client';
import {
  listOpportunities,
  getOpportunity,
  createOpportunity,
  updateOpportunity,
  closeOpportunity,
  expressInterest,
  listMyOpportunities,
  listInterested,
  OpportunityError,
  OpportunityForbiddenError,
  OpportunityNotFoundError,
  OpportunityValidationError,
  OpportunityClosedError,
} from '~/features/opportunities/services/opportunities.service';

describe('opportunities.service', () => {
  beforeEach(() => jest.clearAllMocks());

  describe('listOpportunities', () => {
    it('calls list_opportunities with explicit args and maps the rows to camelCase', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: [
          {
            id: 'o1',
            author_id: 'a1',
            kind: 'hiring',
            title: 'Hiring PM',
            body: 'long body',
            tags: ['pm'],
            location_city: 'Berlin',
            location_country: 'DE',
            remote_ok: true,
            expires_at: '2099-01-01T00:00:00Z',
            created_at: '2026-05-24T12:00:00Z',
            author_handle: 'alice',
            author_name: 'Alice',
            author_photo_url: null,
            author_primary_role: 'founder',
            interested_count: 3,
          },
        ],
        error: null,
      });

      const rows = await listOpportunities({
        kinds: ['hiring'],
        remoteOnly: true,
        search: 'pm',
        limit: 10,
        offset: 5,
      });

      expect(supabase.rpc).toHaveBeenCalledWith('list_opportunities', {
        p_kinds: ['hiring'],
        p_remote_only: true,
        p_search: 'pm',
        p_limit: 10,
        p_offset: 5,
      });
      expect(rows).toEqual([
        {
          id: 'o1',
          authorId: 'a1',
          kind: 'hiring',
          title: 'Hiring PM',
          body: 'long body',
          tags: ['pm'],
          locationCity: 'Berlin',
          locationCountry: 'DE',
          remoteOk: true,
          expiresAt: '2099-01-01T00:00:00Z',
          createdAt: '2026-05-24T12:00:00Z',
          authorHandle: 'alice',
          authorName: 'Alice',
          authorPhotoUrl: null,
          authorPrimaryRole: 'founder',
          interestedCount: 3,
        },
      ]);
    });

    it('passes p_kinds=null when no kinds are requested', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: [], error: null });
      await listOpportunities({});
      expect(supabase.rpc).toHaveBeenCalledWith('list_opportunities', {
        p_kinds: null,
        p_remote_only: false,
        p_search: null,
        p_limit: 20,
        p_offset: 0,
      });
    });

    it('returns [] when the RPC returns null data', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: null, error: null });
      expect(await listOpportunities()).toEqual([]);
    });

    it('throws OpportunityError when the RPC errors', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { code: '28000', message: 'unauthenticated' },
      });
      await expect(listOpportunities()).rejects.toBeInstanceOf(OpportunityError);
    });
  });

  describe('getOpportunity', () => {
    it('returns the first row mapped to camelCase', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: [
          {
            id: 'o1',
            author_id: 'a1',
            kind: 'cofounder',
            title: 'Looking for technical cofounder',
            body: 'body text',
            tags: [],
            location_city: null,
            location_country: null,
            remote_ok: true,
            status: 'open',
            expires_at: null,
            created_at: '2026-05-24T12:00:00Z',
            closed_at: null,
            author_handle: 'alice',
            author_name: 'Alice',
            author_photo_url: null,
            author_primary_role: 'founder',
            interested_count: 0,
            viewer_has_expressed_interest: false,
          },
        ],
        error: null,
      });
      const o = await getOpportunity('o1');
      expect(supabase.rpc).toHaveBeenCalledWith('get_opportunity', { p_id: 'o1' });
      expect(o.id).toBe('o1');
      expect(o.viewerHasExpressedInterest).toBe(false);
      expect(o.status).toBe('open');
    });

    it('throws OpportunityNotFoundError when the row is missing', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: [], error: null });
      await expect(getOpportunity('missing')).rejects.toBeInstanceOf(OpportunityNotFoundError);
    });
  });

  describe('createOpportunity', () => {
    it('passes snake_case args and returns the new id', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: 'new-id', error: null });
      const id = await createOpportunity({
        kind: 'hiring',
        title: 'Hiring a senior PM',
        body: 'Sufficiently long body for the post.',
        tags: ['pm', 'fintech'],
        locationCity: 'Berlin',
        locationCountry: 'DE',
        remoteOk: true,
        expiresAt: null,
      });
      expect(id).toBe('new-id');
      expect(supabase.rpc).toHaveBeenCalledWith('create_opportunity', {
        p_kind: 'hiring',
        p_title: 'Hiring a senior PM',
        p_body: 'Sufficiently long body for the post.',
        p_tags: ['pm', 'fintech'],
        p_location_city: 'Berlin',
        p_location_country: 'DE',
        p_remote_ok: true,
        p_expires_at: null,
      });
    });

    it('maps 22023 validation errors to OpportunityValidationError', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { code: '22023', message: 'title must be 5-120 characters' },
      });
      await expect(
        createOpportunity({
          kind: 'hiring',
          title: 'tiny',
          body: 'long-enough body for the post',
          tags: [],
          remoteOk: false,
        })
      ).rejects.toBeInstanceOf(OpportunityValidationError);
    });
  });

  describe('updateOpportunity', () => {
    it('maps 42501 forbidden errors to OpportunityForbiddenError', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { code: '42501', message: 'opportunity not found or not owned by caller' },
      });
      await expect(
        updateOpportunity('o1', {
          kind: 'hiring',
          title: 'Hiring updated title',
          body: 'updated body for the post',
          tags: [],
          remoteOk: false,
        })
      ).rejects.toBeInstanceOf(OpportunityForbiddenError);
    });
  });

  describe('closeOpportunity', () => {
    it('calls close_opportunity with snake_case args', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: null, error: null });
      await closeOpportunity('o1');
      expect(supabase.rpc).toHaveBeenCalledWith('close_opportunity', { p_id: 'o1' });
    });
  });

  describe('expressInterest', () => {
    it('calls express_interest with optional note', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: null, error: null });
      await expressInterest('o1', '   trimmed note that is long enough   ');
      expect(supabase.rpc).toHaveBeenCalledWith('express_interest', {
        p_opportunity_id: 'o1',
        p_note: 'trimmed note that is long enough',
      });
    });

    it('passes p_note=null when the note is empty', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({ data: null, error: null });
      await expressInterest('o1');
      expect(supabase.rpc).toHaveBeenCalledWith('express_interest', {
        p_opportunity_id: 'o1',
        p_note: null,
      });
    });

    it('maps "not open" 22023 to OpportunityClosedError', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { code: '22023', message: 'opportunity is not open' },
      });
      await expect(expressInterest('o1')).rejects.toBeInstanceOf(OpportunityClosedError);
    });
  });

  describe('listMyOpportunities', () => {
    it('returns mapped rows', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: [
          {
            id: 'o1',
            author_id: 'me',
            kind: 'hiring',
            title: 'Hiring PM',
            body: 'long body',
            tags: ['pm'],
            location_city: null,
            location_country: null,
            remote_ok: false,
            status: 'open',
            expires_at: null,
            created_at: '2026-05-24T12:00:00Z',
            closed_at: null,
            interested_count: 2,
          },
        ],
        error: null,
      });
      const rows = await listMyOpportunities();
      expect(supabase.rpc).toHaveBeenCalledWith('list_my_opportunities', {});
      expect(rows[0]?.status).toBe('open');
      expect(rows[0]?.interestedCount).toBe(2);
    });
  });

  describe('listInterested', () => {
    it('returns mapped rows', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: [
          {
            user_id: 'u1',
            handle: 'bob',
            name: 'Bob',
            photo_url: null,
            primary_role: 'builder',
            note: 'I am interested',
            created_at: '2026-05-24T12:00:00Z',
          },
        ],
        error: null,
      });
      const rows = await listInterested('o1');
      expect(supabase.rpc).toHaveBeenCalledWith('list_interested', { p_opportunity_id: 'o1' });
      expect(rows[0]).toEqual({
        userId: 'u1',
        handle: 'bob',
        name: 'Bob',
        photoUrl: null,
        primaryRole: 'builder',
        note: 'I am interested',
        createdAt: '2026-05-24T12:00:00Z',
      });
    });

    it('maps 42501 to OpportunityForbiddenError', async () => {
      (supabase.rpc as jest.Mock).mockResolvedValueOnce({
        data: null,
        error: { code: '42501', message: 'only the author can view interested users' },
      });
      await expect(listInterested('o1')).rejects.toBeInstanceOf(OpportunityForbiddenError);
    });
  });
});
