import { createClient } from '@supabase/supabase-js';
import { UserProfile, Friend, Sprite, UserSprite } from './types';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_KEY!;

export const supabase = createClient(supabaseUrl, supabaseKey);

/**
 * Устанавливает контекст пользователя для RLS (Row Level Security)
 * @param telegramId Telegram ID пользователя
 */
export const setUserContext = async (telegramId: number): Promise<void> => {
  try {
    const { error } = await supabase
      .rpc('set_current_user', { user_id: telegramId.toString() });
    
    if (error) {
      throw new Error(`RLS error: ${error.message}`);
    }
  } catch (error) {
    throw error;
  }
};
