-- Retire la table de mise de côté des incidents sans club.
--
-- Créée le 13/11 pour garder, hors de portée des clubs, les incidents qui
-- n'avaient pas de club au moment du cloisonnement. Elle est vide en
-- production (vérifié le 26/11 en lecture seule), aucune fonction, vue,
-- règle d'accès ni tâche planifiée ne s'en sert. C'est la seule table de
-- la base sans clé primaire (signalée par le contrôle de performance).
--
-- Risque : nul pour l'appli. Garde-fou : la migration refuse de supprimer
-- la table si elle contient une ligne au moment où elle est appliquée.
-- Retour arrière : recréer la table vide comme dans
-- 20261113010000_journal_incidents_par_club.sql (create table ... like).
do $$
begin
  if exists (select 1 from private.client_incident_log_unassigned) then
    raise exception 'client_incident_log_unassigned n''est pas vide : suppression annulée';
  end if;
end;
$$;

drop table private.client_incident_log_unassigned;
