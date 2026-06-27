import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

serve(async (req) => {
  // Обработка CORS preflight-запроса
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { storyId, chapterId, sceneId } = await req.json();

    if (!storyId || !chapterId || !sceneId) {
      throw new Error('Необходимы storyId, chapterId и sceneId');
    }

    // Создаем Supabase-клиент с правами сервисного ключа.
    // SECURITY DEFINER в новой RPC-функции будет использовать права пользователя из токена.
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    );

    // Получаем пользователя, чтобы передать его ID в RPC
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      throw new Error('Пользователь не авторизован');
    }

    // Вызываем нашу новую, полностью атомарную функцию
    const { error } = await supabase.rpc('update_viewed_scene_truly_atomic', {
      p_user_id: user.id,
      p_story_id: storyId,
      p_chapter_id: chapterId,
      p_scene_id: sceneId,
    });

    if (error) {
      console.error('Ошибка в Edge Function при вызове update_viewed_scene_truly_atomic:', error);
      throw error;
    }

    return new Response(JSON.stringify({ message: 'Прогресс успешно обновлен' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
