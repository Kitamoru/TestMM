import type { NextApiRequest, NextApiResponse } from 'next';
import { supabase } from '@/lib/supabase';
import { validateTelegramInitData, extractTelegramUser } from '@/lib/telegramAuth';
import { UserProfile } from '@/lib/types';

interface DataResponse {
  success: boolean;
  data?: UserProfile;
  error?: string;
}

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse<DataResponse>
) {
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
  res.setHeader('Pragma', 'no-cache');
  res.setHeader('Expires', '0');

  if (req.method !== 'GET') {
    return res.status(405).json({ success: false, error: 'Method not allowed' });
  }

  const initData = req.headers['x-telegram-init-data'] as string;
  if (!initData || !validateTelegramInitData(initData)) {
    return res.status(401).json({ success: false, error: 'Unauthorized' });
  }

  try {
    const telegramId = req.query.telegramId as string;

    if (!telegramId) {
      return res.status(400).json({ success: false, error: 'telegramId required' });
    }

    const telegramIdNumber = Number(telegramId);
    if (isNaN(telegramIdNumber)) {
      return res.status(400).json({ success: false, error: 'Invalid telegramId format' });
    }

    const telegramUser = extractTelegramUser(initData);
    if (!telegramUser) {
      return res.status(400).json({ success: false, error: 'Invalid user data' });
    }

    const userTelegramId = Number(telegramUser.id);
    if (isNaN(userTelegramId)) {
      return res.status(400).json({ success: false, error: 'Invalid Telegram ID' });
    }

    if (userTelegramId !== telegramIdNumber) {
      return res.status(403).json({ success: false, error: 'Forbidden' });
    }

    const { data: user, error: dbError } = await supabase
      .from('users')
      .select(`
        *,
        sprites:current_sprite_id (image_url)
      `)
      .eq('telegram_id', telegramIdNumber)
      .single();

    if (dbError) {
      if (dbError.code === 'PGRST116') { // Код "Resource not found"
        return res.status(404).json({ 
          success: false,
          error: 'User not found. Please complete initialization first.'
        });
      }
      
      return res.status(500).json({ 
        success: false,
        error: 'Database error'
      });
    }

    const userData: UserProfile = {
      id: user.id,
      telegram_id: user.telegram_id,
      created_at: user.created_at,
      username: user.username,
      first_name: user.first_name,
      last_name: user.last_name,
      burnout_level: user.burnout_level,
      last_attempt_date: user.last_attempt_date,
      coins: user.coins,
      updated_at: user.updated_at,
      current_sprite_id: user.current_sprite_id,
      last_login_date: user.last_login_date,
      current_sprite_url: user.sprites?.image_url || null,
      character_class: user.character_class
    };

    return res.status(200).json({
      success: true,
      data: userData
    });

  } catch (error: any) {
    return res.status(500).json({ 
      success: false,
      error: 'Internal server error'
    });
  }
}
