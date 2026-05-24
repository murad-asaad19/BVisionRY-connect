jest.mock('~/lib/supabase/client', () => ({
  supabase: {
    storage: {
      from: jest.fn(),
    },
  },
}));

import { supabase } from '~/lib/supabase/client';
import { uploadAvatar, uploadChatMedia } from '~/features/media/services/storage.service';

describe('storage.service', () => {
  beforeEach(() => jest.clearAllMocks());

  it('uploadAvatar puts to {userId}/avatar.{ext} with upsert and returns cache-busted URL', async () => {
    const blob = new Blob(['x'], { type: 'image/jpeg' });
    const bucket = {
      upload: jest.fn().mockResolvedValue({ data: { path: 'p' }, error: null }),
      getPublicUrl: jest.fn(() => ({ data: { publicUrl: 'https://example/p.jpg' } })),
    };
    (supabase.storage.from as jest.Mock).mockReturnValue(bucket);
    const url = await uploadAvatar('user-123', blob, 'jpg');
    expect(supabase.storage.from).toHaveBeenCalledWith('avatars');
    expect(bucket.upload).toHaveBeenCalledWith(
      'user-123/avatar.jpg',
      blob,
      expect.objectContaining({ contentType: 'image/jpeg', upsert: true })
    );
    // The service appends `?v=<now>` so the device-level image cache busts
    // when the avatar is re-uploaded with the same stable filename.
    expect(url).toMatch(/^https:\/\/example\/p\.jpg\?v=\d+$/);
  });

  it('uploadChatMedia puts to {convId}/{msgId}/media.{ext} and returns path', async () => {
    const blob = new Blob(['x'], { type: 'image/jpeg' });
    const bucket = {
      upload: jest.fn().mockResolvedValue({ data: { path: 'p' }, error: null }),
    };
    (supabase.storage.from as jest.Mock).mockReturnValue(bucket);
    const path = await uploadChatMedia('conv-1', 'msg-1', blob, 'jpg', 'image/jpeg');
    expect(supabase.storage.from).toHaveBeenCalledWith('chat-media');
    expect(bucket.upload).toHaveBeenCalledWith(
      'conv-1/msg-1/media.jpg',
      blob,
      expect.objectContaining({ contentType: 'image/jpeg' })
    );
    expect(path).toBe('conv-1/msg-1/media.jpg');
  });

  it('throws on upload error', async () => {
    const blob = new Blob(['x']);
    const bucket = {
      upload: jest.fn().mockResolvedValue({ data: null, error: { message: 'nope' } }),
    };
    (supabase.storage.from as jest.Mock).mockReturnValue(bucket);
    await expect(uploadAvatar('u', blob, 'jpg')).rejects.toThrow('nope');
  });
});
