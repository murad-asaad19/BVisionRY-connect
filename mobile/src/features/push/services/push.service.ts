import { supabase } from '~/lib/supabase/client';
import type { Database } from '~/lib/supabase/types.gen';

export type DevicePlatform = Database['public']['Enums']['device_platform'];
export type DeviceTokenRow = Database['public']['Tables']['device_tokens']['Row'];

export async function registerDeviceToken(
  token: string,
  platform: DevicePlatform
): Promise<DeviceTokenRow> {
  const { data, error } = await supabase.rpc('register_device_token', {
    p_token: token,
    p_platform: platform,
  });
  if (error) throw new Error(error.message);
  return data as DeviceTokenRow;
}
