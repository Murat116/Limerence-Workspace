-- DialogAudio: action-only model + loop

alter table "DialogAudio"
  add column if not exists loop boolean not null default false;

-- play + play_mode → новые action (если колонка play_mode ещё есть)
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'DialogAudio' and column_name = 'play_mode'
  ) then
    update "DialogAudio"
    set action = case
      when action = 'play' and coalesce(play_mode, 'stop_others') = 'overlay' then 'play_overlay'
      when action = 'play' then 'stop_other_play'
      when action = 'stop_bgm' then 'stop_all'
      else action
    end;
  end if;
end $$;

update "DialogAudio"
set action = 'stop_other_play', loop = coalesce(loop, false)
where action not in ('stop_other_play', 'play_overlay', 'stop_all');

alter table "DialogAudio" drop constraint if exists "DialogAudio_action_check";
alter table "DialogAudio" drop constraint if exists "DialogAudio_play_mode_check";
alter table "DialogAudio" drop column if exists play_mode;

alter table "DialogAudio"
  add constraint "DialogAudio_action_check"
  check (action in ('stop_other_play', 'play_overlay', 'stop_all'));
