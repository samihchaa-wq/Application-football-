-- Journal des incidents de l'application : un club par ligne.
--
-- Constaté lors du test de cloisonnement du 12/11/2026 sur la base
-- commerciale : la table private.client_incident_log était commune à tous les
-- clubs, et public.admin_recent_client_incidents() la renvoyait en entier.
-- L'administrateur d'un club voyait donc les incidents envoyés par les
-- membres des autres clubs, et n'importe quel membre pouvait faire apparaître
-- un texte libre chez les administrateurs de tous les clubs.
--
-- Correctif : la table reçoit un club_id et la même règle restrictive que
-- les autres tables métier. La fonction de lecture, qui appartient à
-- club_scope, ne voit plus que les lignes du club courant. La purge
-- quotidienne passe club par club, comme les autres tâches planifiées.

alter table private.client_incident_log
  add column club_id uuid
    default private.current_club_id()
    references public.clubs(id) on delete cascade;

update private.client_incident_log entry
set club_id = profile.club_id
from public.profiles profile
where profile.id = entry.profile_id
  and entry.club_id is null;

-- Lignes techniques sans auteur rattachable : rien à conserver.
delete from private.client_incident_log where club_id is null;

alter table private.client_incident_log alter column club_id set not null;

create index client_incident_log_club_id_idx
  on private.client_incident_log (club_id);

drop policy if exists club_scope_access on private.client_incident_log;

create policy club_isolation on private.client_incident_log
  as restrictive for all to public
  using (club_id = (select private.current_club_id()))
  with check (club_id = (select private.current_club_id()));

create policy club_scope_access on private.client_incident_log
  for all to club_scope using (true) with check (true);

-- La purge appartient à club_scope : sans club courant, la règle ci-dessus
-- ne lui laisserait rien à supprimer. Elle passe donc club par club.
select cron.schedule(
  'purge-client-incident-log',
  '17 3 * * *',
  $cron$select private.run_for_each_club('select private.purge_client_incident_log(now())');$cron$
);
