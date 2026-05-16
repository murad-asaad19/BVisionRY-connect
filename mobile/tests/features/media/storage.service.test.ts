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

  it('uploadAvatar puts to {userId}/avatar-{ts}.jpg and returns public URL', async () => {
    const blob = new Blob(['x'], { type: 'image/jpeg' });
    const bucket = {
      upload: jest.fn().mockResolvedValue({ data: { path: 'p' }, error: null }),
      getPublicUrl: jest.fn(() => ({ data: { publicUrl: 'https://example/p.jpg' } })),
    };
    (supabase.storage.from as jest.Mock).mockReturnValue(bucket);
    const url = await uploadAvatar('user-123', blob, 'jpg');
    expect(supabase.storage.from).toHaveBeenCalledWith('avatars');
    expect(bucket.upload).toHaveBeenCalledWith(
      expect.stringMatching(/^user-123\/avatar-\d+\.jpg$/),
      blob,
      expect.objectContaining({ contentType: 'image/jpeg', upsert: true })
    );
    expect(url).toBe('https://example/p.jpg');
  });

  it('uploadChatMedia puts to {convId}/{msgId}/{file} and returns path', async () => {
    const blob = new Blob(['x'], { type: 'image/jpeg' });
    const bucket = {
      upload: jest.fn().mockResolvedValue({ data: { path: 'p' }, error: null }),
    };
    (supabase.storage.from as jest.Mock).mockReturnValue(bucket);
    const path = await uploadChatMedia('conv-1', 'msg-1', blob, 'jpg', 'image/jpeg');
    expect(supabase.storage.from).toHaveBeenCalledWith('chat-media');
    expect(bucket.upload).toHaveBeenCalledWith(
      expect.stringMatching(/^conv-1\/msg-1\/[a-z0-9-]+\.jpg$/),
      blob,
      expect.objectContaining({ contentType: 'image/jpeg' })
    );
    expect(path).toMatch(/^conv-1\/msg-1\//);
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
