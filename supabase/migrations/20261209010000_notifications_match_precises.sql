-- Notifications précises quand un détail d'un match change.
--
-- Avant : seuls l'annulation et le changement de date ou d'heure prévenaient
-- les joueurs. Un changement d'adresse, de maillot, de lieu (domicile /
-- extérieur) ou d'heure de rendez-vous ne disait rien.
--
-- Maintenant : une notification par détail, avec un titre qui dit
-- exactement ce qui a changé. Un même enregistrement qui change plusieurs
-- détails envoie plusieurs notifications (une par détail).
--
-- * match_address_changed  → « Adresse du match modifiée »
-- * match_jersey_changed   → « Maillot modifié »
-- * match_meeting_changed  → « Heure de rendez-vous modifiée »
-- * match_location_changed → « Domicile / extérieur modifié »
--
-- Destinataires : les joueurs éligibles du match et le coach, comme pour
-- le changement d'horaire. Rien ne part si le match n'est plus « à venir »,
-- si son coup d'envoi est passé, ou si les notifications sont en pause.
-- Les clubs coupent ces quatre types avec l'interrupteur déjà existant
-- « Match annulé ou déplacé » (notify_match_changes).

create or replace function private.club_notification_rules()
returns table (kind text, rule_key text)
language sql immutable
set search_path to ''
as $$
  select * from (values
    ('availability_open', 'notify_availability_open'),
    ('availability_manual', 'notify_availability_open'),
    ('availability_j3', 'notify_availability_reminders'),
    ('availability_j1', 'notify_availability_reminders'),
    ('convocation_promoted', 'notify_convocation'),
    ('convocation_demoted', 'notify_convocation'),
    ('composition_published', 'notify_composition'),
    ('match_cancelled', 'notify_match_changes'),
    ('match_rescheduled_date', 'notify_match_changes'),
    ('match_rescheduled_time', 'notify_match_changes'),
    ('match_address_changed', 'notify_match_changes'),
    ('match_jersey_changed', 'notify_match_changes'),
    ('match_meeting_changed', 'notify_match_changes'),
    ('match_location_changed', 'notify_match_changes'),
    ('live_kickoff', 'notify_live_kickoff'),
    ('live_full_time', 'notify_live_kickoff'),
    ('live_goal_us', 'notify_live_goals'),
    ('live_goal_them', 'notify_live_goals'),
    ('prediction_j5', 'notify_prediction_reminder'),
    ('motm_open', 'notify_motm_open'),
    ('motm_result_general', 'notify_motm_result'),
    ('motm_result_winner', 'notify_motm_result'),
    ('badge_unlocked', 'notify_badges'),
    ('admin_pending_signup', 'notify_admin_signups')
,
    ('availability_j3', 'notify_availability_j3'),
    ('availability_j1', 'notify_availability_j1'),
    ('live_full_time', 'notify_live_full_time'),
    ('live_goal_us', 'notify_live_goal_us'),
    ('live_goal_them', 'notify_live_goal_them'),
    ('match_cancelled', 'notify_match_cancelled'),
    ('match_rescheduled_date', 'notify_match_rescheduled_date'),
    ('match_rescheduled_time', 'notify_match_rescheduled_time'),
    ('convocation_promoted', 'notify_convocation_promoted'),
    ('convocation_demoted', 'notify_convocation_demoted'),
    ('motm_result_winner', 'notify_motm_winner')
  ) as mapping(kind, rule_key);
$$;

-- Le journal de livraison ne connaît que des types listés : les nouveaux
-- types y sont ajoutés (sinon l'envoi y serait journalisé « custom »).
alter table public.push_delivery_log
  drop constraint if exists push_delivery_log_kind_check;
alter table public.push_delivery_log
  add constraint push_delivery_log_kind_check check (kind = any (array[
    'availability_open', 'availability_j3', 'availability_j1',
    'availability_manual', 'motm_open', 'prediction_j5', 'match_cancelled',
    'match_rescheduled_date', 'match_rescheduled_time',
    'match_address_changed', 'match_jersey_changed',
    'match_meeting_changed', 'match_location_changed',
    'convocation_promoted', 'convocation_demoted', 'composition_published',
    'motm_result_general', 'motm_result_winner', 'badge_unlocked',
    'admin_pending_signup', 'test', 'custom', 'live_kickoff',
    'live_goal_us', 'live_goal_them', 'live_full_time'
  ]::text[]));

create or replace function private.handle_match_detail_notification_change()
returns trigger
language plpgsql security definer
set search_path to ''
as $$
declare
  v_token text;
  v_recipients uuid[];
  v_opponent text;
  v_date text;
  v_who text;
  v_kind text;
  v_title text;
  v_message text;
  v_changes jsonb := '[]'::jsonb;
  v_change jsonb;
begin
  -- Seul un match à venir, dont le coup d'envoi n'est pas passé, prévient.
  if new.status is distinct from 'a_venir'
     or new.kickoff_at is null
     or new.kickoff_at <= now() then
    return new;
  end if;
  -- Un report ou une annulation a déjà sa propre notification.
  if old.kickoff_at is distinct from new.kickoff_at
     or old.status is distinct from new.status then
    return new;
  end if;
  if private.is_feature_enabled('notifications_paused') then
    return new;
  end if;

  select opponent.name into v_opponent
  from public.opponents opponent
  where opponent.id = new.opponent_id;

  v_date := to_char(new.kickoff_at at time zone 'Europe/Paris', 'DD/MM');
  v_who := case
    when v_opponent is null then 'le match entre nous du ' || v_date
    else 'le match du ' || v_date || ' contre ' || v_opponent
  end;

  if old.address is distinct from new.address then
    v_changes := v_changes || jsonb_build_array(jsonb_build_object(
      'kind', 'match_address_changed',
      'title', 'Adresse du match modifiée',
      'message', case
        when nullif(btrim(coalesce(new.address, '')), '') is null
          then 'L’adresse de ' || v_who || ' a été retirée.'
        else 'Nouvelle adresse pour ' || v_who || ' : '
          || btrim(new.address) || '.'
      end
    ));
  end if;

  if old.jersey_note is distinct from new.jersey_note then
    v_changes := v_changes || jsonb_build_array(jsonb_build_object(
      'kind', 'match_jersey_changed',
      'title', 'Maillot modifié',
      'message', case
        when nullif(btrim(coalesce(new.jersey_note, '')), '') is null
          then 'Plus de consigne de maillot pour ' || v_who || '.'
        else 'Maillot pour ' || v_who || ' : '
          || btrim(new.jersey_note) || '.'
      end
    ));
  end if;

  if old.meeting_at is distinct from new.meeting_at then
    v_changes := v_changes || jsonb_build_array(jsonb_build_object(
      'kind', 'match_meeting_changed',
      'title', 'Heure de rendez-vous modifiée',
      'message', case
        when new.meeting_at is null
          then 'Plus d’heure de rendez-vous pour ' || v_who || '.'
        else 'Rendez-vous à '
          || private.match_notification_time_label(new.meeting_at)
          || ' pour ' || v_who || '.'
      end
    ));
  end if;

  if old.location is distinct from new.location then
    v_changes := v_changes || jsonb_build_array(jsonb_build_object(
      'kind', 'match_location_changed',
      'title', 'Domicile ou extérieur modifié',
      'message', initcap(v_who) || ' se jouera '
        || case new.location
             when 'domicile' then 'à domicile'
             else 'à l’extérieur'
           end || '.'
    ));
  end if;

  if jsonb_array_length(v_changes) = 0 then
    return new;
  end if;

  select array_agg(profile.id order by profile.id)
  into v_recipients
  from public.profiles profile
  where profile.status = 'active'
    and exists (
      select 1
      from public.match_sport_participants participant
      join public.season_players player on player.id = participant.season_player_id
      where participant.match_id = new.id
        and (participant.is_eligible or player.is_coach)
        and player.profile_id = profile.id
    );

  if v_recipients is null or cardinality(v_recipients) = 0 then
    return new;
  end if;

  select secret.decrypted_secret into v_token
  from private.vault_secrets() secret
  where secret.name = 'push_internal_token';

  if v_token is null then
    return new;
  end if;

  for v_change in select value from jsonb_array_elements(v_changes)
  loop
    perform private.http_post(
      url := private.edge_function_url('send-push'),
      body := jsonb_build_object(
        'kind', 'custom',
        'log_kind', v_change ->> 'kind',
        'match_id', new.id,
        'profile_ids', to_jsonb(v_recipients),
        'title', v_change ->> 'title',
        'message', v_change ->> 'message',
        'url', 'matches/' || new.id || '/lineup?section=info'
      ),
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-push-token', v_token
      ),
      timeout_milliseconds := 10000
    );
  end loop;

  return new;
exception when others then
  -- L'envoi ne doit jamais faire échouer la modification du match.
  return new;
end;
$$;

-- Soumise au cloisonnement par club, comme les autres fonctions privilégiées.
alter function private.handle_match_detail_notification_change() owner to club_scope;
revoke all on function private.handle_match_detail_notification_change()
  from public, anon, authenticated;

drop trigger if exists trg_notification_match_detail_changes on public.matches;
create trigger trg_notification_match_detail_changes
after update of address, jersey_note, meeting_at, location
on public.matches
for each row
execute function private.handle_match_detail_notification_change();

-- Effacer toute la boîte de réception d'un coup (bouton « Effacer toutes »).
create or replace function public.delete_my_notifications()
returns integer
language plpgsql security definer
set search_path to ''
as $$
declare
  v_actor uuid := (select private.uid());
  v_count integer;
begin
  if v_actor is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.profiles profile
    where profile.id = v_actor
      and profile.status = 'active'
  ) then
    raise exception 'Active profile not found' using errcode = '42501';
  end if;

  -- Uniquement les lignes du demandeur.
  delete from private.notification_history history
  where history.profile_id = v_actor;
  get diagnostics v_count = row_count;

  return v_count;
end;
$$;

-- Soumise au cloisonnement par club, comme les autres fonctions privilégiées.
alter function public.delete_my_notifications() owner to club_scope;

comment on function public.delete_my_notifications() is
  'Supprime définitivement toutes les notifications de l''historique du compte connecté et rend leur nombre. Profil actif exigé.';

revoke all on function public.delete_my_notifications() from public, anon;
grant all on function public.delete_my_notifications() to service_role;
grant all on function public.delete_my_notifications() to authenticated;

-- Arriver sur l'écran qu'annonce une notification (par la notification ou
-- par un autre chemin) la marque lue : le chiffre de la cloche et la
-- pastille de l'icône baissent. Seules les notifications du demandeur, du
-- ou des types demandés, et du match demandé (s'il est donné) sont touchées.
create or replace function public.mark_my_notifications_read_for(
  p_kinds text[],
  p_match_id uuid default null
)
returns integer
language plpgsql security definer
set search_path to ''
as $$
declare
  v_actor uuid := (select private.uid());
  v_count integer;
begin
  if v_actor is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.profiles profile
    where profile.id = v_actor
      and profile.status = 'active'
  ) then
    raise exception 'Active profile not found' using errcode = '42501';
  end if;

  if p_kinds is null or cardinality(p_kinds) = 0 then
    return 0;
  end if;

  update private.notification_history history
  set read_at = now()
  where history.profile_id = v_actor
    and history.read_at is null
    and history.kind = any (p_kinds)
    and (p_match_id is null or history.match_id = p_match_id);
  get diagnostics v_count = row_count;

  return v_count;
end;
$$;

alter function public.mark_my_notifications_read_for(text[], uuid) owner to club_scope;

comment on function public.mark_my_notifications_read_for(text[], uuid) is
  'Marque comme lues les notifications non lues du compte connecté pour les types donnés (et le match donné, si présent) et rend leur nombre. Profil actif exigé.';

revoke all on function public.mark_my_notifications_read_for(text[], uuid) from public, anon;
grant all on function public.mark_my_notifications_read_for(text[], uuid) to service_role;
grant all on function public.mark_my_notifications_read_for(text[], uuid) to authenticated;
