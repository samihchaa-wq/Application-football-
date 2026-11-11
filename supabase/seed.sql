-- Données de départ pour une installation locale ou de test uniquement.
-- Jamais exécuté sur une base réelle.
--
-- Crée un club de démonstration et en fait le club par défaut des sessions
-- techniques, pour que les tests et les essais locaux écrivent leurs données
-- dans ce club sans avoir à le préciser.
do $$
declare
  v_club public.clubs;
begin
  v_club := public.create_club('Club de démonstration', 'DEMO');
  insert into private.local_default_club (club_id) values (v_club.id);
end;
$$;
