-- Une fonctionnalité désactivée par l'administrateur du club n'était que
-- cachée dans l'application. Le serveur refuse maintenant lui aussi un
-- pronostic ou un vote d'homme du match quand le club a coupé la fonction.

-- Vrai si la fonctionnalité est activée pour le club courant (activée par
-- défaut tant que le club n'a rien réglé).
create function private.club_module_enabled(p_key text) returns boolean
language sql stable security definer
set search_path to ''
as $$
  select coalesce(
    (
      select flag.enabled
      from private.app_feature_flags flag
      where flag.key = p_key
        and flag.club_id = (select private.current_club_id())
    ),
    true
  );
$$;

alter function private.club_module_enabled(text) owner to club_scope;
revoke all on function private.club_module_enabled(text) from public, anon;
grant execute on function private.club_module_enabled(text)
  to authenticated, service_role, club_scope;

-- Pronostics : on refuse d'enregistrer ou de modifier un score pronostiqué.
-- Les lignes vides préparées automatiquement pour chaque match restent permises.
create function private.guard_predictions_module() returns trigger
language plpgsql
set search_path to ''
as $$
begin
  if new.is_filled
     and (
       tg_op = 'INSERT'
       or (old.is_filled, old.predicted_score_as_grinta, old.predicted_score_adverse)
          is distinct from
          (new.is_filled, new.predicted_score_as_grinta, new.predicted_score_adverse)
     )
     and not private.club_module_enabled('predictions') then
    raise exception 'Les pronostics sont désactivés pour ce club.'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

revoke all on function private.guard_predictions_module() from public, anon;

create trigger guard_predictions_module
before insert or update on public.match_predictions
for each row execute function private.guard_predictions_module();

-- Homme du match : on refuse tout nouveau vote.
create function private.guard_motm_module() returns trigger
language plpgsql
set search_path to ''
as $$
begin
  if not private.club_module_enabled('man_of_the_match') then
    raise exception 'Le vote de l’homme du match est désactivé pour ce club.'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

revoke all on function private.guard_motm_module() from public, anon;

create trigger guard_motm_module
before insert on public.match_sport_motm_votes
for each row execute function private.guard_motm_module();
