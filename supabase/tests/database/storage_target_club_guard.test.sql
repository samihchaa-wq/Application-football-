-- Contrat de sûreté complémentaire aux scénarios HTTP Storage à deux clubs.
-- Exécuté uniquement dans la base jetable de la CI Supabase.
begin;
set local search_path = public, extensions, pg_catalog;

select plan(5);

select ok(
  to_regprocedure('private.storage_path_in_current_club(text,text)') is not null,
  'la validation des dossiers Storage est installee'
);

select ok(
  exists (
    select 1 from pg_proc p
    where p.oid = 'private.storage_path_in_current_club(text,text)'::regprocedure
      and p.prosecdef
      and pg_get_userbyid(p.proowner) = 'club_scope'
  ),
  'contrat SECURITY DEFINER et proprietaire maintenus'
);

select ok(
  position('guest.club_id = v_club' in
    pg_get_functiondef('private.storage_path_in_current_club(text,text)'::regprocedure)) > 0,
  'un dossier invite doit verifier explicitement le club de la cible'
);

select ok(
  position('player.club_id = v_club' in
    pg_get_functiondef('private.storage_path_in_current_club(text,text)'::regprocedure)) > 0,
  'un dossier joueur de saison doit verifier explicitement le club de la cible'
);

select ok(
  position('profile.club_id = v_club' in
    pg_get_functiondef('private.storage_path_in_current_club(text,text)'::regprocedure)) > 0,
  'un dossier profil doit verifier explicitement le club de la cible'
);

select * from finish();
rollback;
