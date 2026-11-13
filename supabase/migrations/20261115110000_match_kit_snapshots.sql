-- Snapshot immuable des maillots choisis pour un match Petit Filet.
-- Aucune écriture depuis le client : enregistrement par déclencheurs au premier
-- début du Live ou à la finalisation, avec cloisonnement strict par club.
-- La migration des couleurs gardien 20261115010000 reste indépendante
-- (elle peut ne pas encore être appliquée sur la base commerciale).

create table public.match_kit_snapshots (
  match_id uuid primary key references public.matches(id) on delete cascade,
  club_id uuid not null references public.clubs(id) on delete cascade,
  jersey_id text not null check (jersey_id in ('france','orange','blue')),
  kit jsonb not null check (jsonb_typeof(kit) = 'object'),
  kits jsonb not null check (jsonb_typeof(kits) = 'array' and jsonb_array_length(kits) = 3),
  team1_kit jsonb check (team1_kit is null or jsonb_typeof(team1_kit) = 'object'),
  team2_kit jsonb check (team2_kit is null or jsonb_typeof(team2_kit) = 'object'),
  captured_at timestamptz not null default now()
);
create index match_kit_snapshots_club_id_idx
  on public.match_kit_snapshots(club_id);

alter table public.match_kit_snapshots enable row level security;
revoke all on public.match_kit_snapshots from public, anon, authenticated;
grant select on public.match_kit_snapshots to authenticated, service_role;

create policy match_kit_snapshots_member_read
on public.match_kit_snapshots for select to authenticated
using (
  club_id = (select private.current_club_id())
  and (select private.is_active_profile())
);

-- Defense in depth: a restrictive policy ensures that future permissive
-- policies cannot accidentally expose another club's snapshots.
create policy club_isolation
on public.match_kit_snapshots as restrictive for all to authenticated
using (club_id = (select private.current_club_id()))
with check (club_id = (select private.current_club_id()));

-- Required security baseline for every public business table.
create policy active_authenticated_profile_only
on public.match_kit_snapshots as restrictive for all to authenticated
using ((select private.is_active_profile()))
with check ((select private.is_active_profile()));

comment on table public.match_kit_snapshots is
  'Couleurs des trois maillots figées au Live ou à la fin du match. Lecture seule pour les membres du club, pas de modification depuis le client.';

-- Reconstitue toujours un objet complet, même pour un club ancien dont les
-- maillots et couleurs de gardien n'ont jamais été configurés.
create function private.match_kit_snapshot_value(
  p_kits jsonb,
  p_primary text,
  p_secondary text,
  p_slot text
) returns jsonb
language plpgsql stable
set search_path to ''
as $$
declare
  v_slot text := case when p_slot in ('france','orange','blue')
    then p_slot else 'france' end;
  v_kit jsonb;
  v_body text;
  v_trim text;
  v_label text;
  v_gk_body text;
begin
  if jsonb_typeof(p_kits) = 'array' then
    select elem.value into v_kit
    from jsonb_array_elements(p_kits) as elem(value)
    where elem.value ->> 'slot' = v_slot
    limit 1;
  end if;

  v_body := case v_slot
    when 'france' then coalesce(p_primary, '#1F6FEB')
    when 'orange' then '#FFFFFF'
    else '#1B1F2A'
  end;
  v_trim := case v_slot
    when 'orange' then coalesce(p_primary, '#1F6FEB')
    else coalesce(p_secondary, '#FFFFFF')
  end;
  v_label := case v_slot
    when 'france' then 'Domicile'
    when 'orange' then 'Extérieur'
    else 'Troisième'
  end;
  v_gk_body := case v_slot
    when 'france' then '#168A52'
    when 'orange' then '#F5A300'
    else '#1F6FEB'
  end;
  return jsonb_build_object(
    'slot', v_slot,
    'label', coalesce(v_kit ->> 'label', v_label),
    'body', coalesce(v_kit ->> 'body', v_body),
    'trim', coalesce(v_kit ->> 'trim', v_trim),
    'goalkeeper_body', coalesce(v_kit ->> 'goalkeeper_body', v_gk_body),
    'goalkeeper_trim', coalesce(v_kit ->> 'goalkeeper_trim', '#FFFFFF'),
    'enabled', coalesce((v_kit ->> 'enabled')::boolean, true)
  );
end;
$$;

-- Une insertion ON CONFLICT DO NOTHING conserve la photographie initiale.
-- Si une feuille "entre nous" est publiée après la clôture d'un match
-- historique, seules ses valeurs manquantes sont complétées, à partir du
-- trio de maillots DÉJÀ figé, jamais des couleurs actuelles du club.
create function private.capture_match_kit_snapshot(p_match_id uuid)
returns void
language plpgsql security definer
set search_path to ''
as $$
declare
  v_match record;
  v_kits jsonb;
  v_slot text;
begin
  select m.club_id, m.jersey_note, m.match_type,
         c.kits as club_kits, c.primary_color, c.secondary_color,
         i.team1_jersey, i.team2_jersey
  into v_match
  from public.matches m
  join public.clubs c on c.id = m.club_id
  left join public.match_internal_compositions i
    on i.match_id = m.id and i.club_id = m.club_id
  where m.id = p_match_id;
  if not found then return; end if;

  v_slot := case when v_match.jersey_note in ('france','orange','blue')
    then v_match.jersey_note else 'france' end;
  v_kits := jsonb_build_array(
    private.match_kit_snapshot_value(
      v_match.club_kits, v_match.primary_color, v_match.secondary_color, 'france'),
    private.match_kit_snapshot_value(
      v_match.club_kits, v_match.primary_color, v_match.secondary_color, 'orange'),
    private.match_kit_snapshot_value(
      v_match.club_kits, v_match.primary_color, v_match.secondary_color, 'blue')
  );

  insert into public.match_kit_snapshots(
    match_id, club_id, jersey_id, kit, kits, team1_kit, team2_kit
  ) values (
    p_match_id,
    v_match.club_id,
    v_slot,
    (select elem.value from jsonb_array_elements(v_kits) as elem(value)
      where elem.value ->> 'slot' = v_slot limit 1),
    v_kits,
    case when v_match.match_type = 'entre_nous' then
      (select elem.value from jsonb_array_elements(v_kits) as elem(value)
       where elem.value ->> 'slot' = v_match.team1_jersey limit 1)
    end,
    case when v_match.match_type = 'entre_nous' then
      (select elem.value from jsonb_array_elements(v_kits) as elem(value)
       where elem.value ->> 'slot' = v_match.team2_jersey limit 1)
    end
  )
  on conflict (match_id) do nothing;

  if v_match.match_type = 'entre_nous' then
    update public.match_kit_snapshots s
    set team1_kit = coalesce(
          s.team1_kit,
          (select elem.value from jsonb_array_elements(s.kits) as elem(value)
           where elem.value ->> 'slot' = v_match.team1_jersey limit 1)
        ),
        team2_kit = coalesce(
          s.team2_kit,
          (select elem.value from jsonb_array_elements(s.kits) as elem(value)
           where elem.value ->> 'slot' = v_match.team2_jersey limit 1)
        )
    where s.match_id = p_match_id
      and (s.team1_kit is null or s.team2_kit is null);
  end if;
end;
$$;

revoke all on function private.match_kit_snapshot_value(jsonb,text,text,text)
  from public, anon, authenticated;
revoke all on function private.capture_match_kit_snapshot(uuid)
  from public, anon, authenticated;

create function private.trigger_match_kit_snapshot()
returns trigger
language plpgsql security definer
set search_path to ''
as $$
begin
  if TG_TABLE_NAME = 'matches' then
    perform private.capture_match_kit_snapshot(new.id);
  elsif TG_TABLE_NAME = 'match_internal_compositions' then
    -- Ne PAS figer les couleurs pendant la préparation d'un match !
    -- Compléter seulement une feuille déjà figée (Live commencé), ou
    -- la première saisie d'un ancien match terminé.
    if exists (
      select 1 from public.match_kit_snapshots s
      where s.match_id = new.match_id
    ) or exists (
      select 1 from public.matches m
      where m.id = new.match_id and m.status in ('termine','archive')
    ) then
      perform private.capture_match_kit_snapshot(new.match_id);
    end if;
  else
    perform private.capture_match_kit_snapshot(new.match_id);
  end if;
  return new;
end;
$$;
revoke all on function private.trigger_match_kit_snapshot()
  from public, anon, authenticated;

-- Live : une couleur définie après le coup d'envoi ne change pas les photos
-- de la saison, ni les badges du match déjà commencé.
create trigger trg_match_kit_snapshot_live_start
after insert or update of started_at on public.match_live_sessions
for each row when (new.started_at is not null)
execute function private.trigger_match_kit_snapshot();

-- Match sans Live et archives importées : capturer lors de la clôture.
create trigger trg_match_kit_snapshot_finished_insert
after insert on public.matches
for each row when (new.status in ('termine','archive'))
execute function private.trigger_match_kit_snapshot();

create trigger trg_match_kit_snapshot_finished_update
after update of status on public.matches
for each row when (new.status in ('termine','archive'))
execute function private.trigger_match_kit_snapshot();

-- Une composition historique "entre nous" peut être saisie en différé.
create trigger trg_match_kit_snapshot_internal_jerseys
after insert or update of team1_jersey, team2_jersey
on public.match_internal_compositions
for each row
execute function private.trigger_match_kit_snapshot();

-- Backfill : meilleure approximation pour les matchs déjà terminés :
-- leurs anciennes couleurs n'étaient pas enregistrées. Le commentaire
-- prévient qu'on ne peut pas retrouver une photographie passée avec certitude.
select private.capture_match_kit_snapshot(m.id)
from public.matches m
where m.status in ('termine','archive');
