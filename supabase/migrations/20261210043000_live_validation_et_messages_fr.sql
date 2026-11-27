-- Live : règles cohérentes avec le compte rendu, messages en français.
--
-- 1. Un Live lancé puis terminé avant l'heure officielle laissait le compte
--    rendu bloqué : « Un match futur ne peut pas être marqué terminé ». La
--    validation (private.finalize_match_sport_postgame) acceptait déjà un
--    match dont le Live est terminé ; le garde-fou de la table matches est
--    aligné sur la même règle.
--
-- 2. Les messages d'erreur des fonctions du Live et du compte rendu étaient
--    en anglais, certains avec « AS Grinta » écrit en dur. Ils sont traduits
--    en français simple (« ton équipe » à la place du nom du club). Seuls les
--    textes entre apostrophes sont remplacés, la logique des fonctions ne
--    change pas : chaque fonction est relue telle qu'elle est en base
--    (pg_get_functiondef), corrigée, puis recréée (propriétaire et droits
--    conservés par CREATE OR REPLACE).

create or replace function private.guard_match_status_chronology()
returns trigger
language plpgsql
set search_path to ''
as $$
declare
  v_kickoff timestamptz;
begin
  if new.match_date is null or new.match_time is null then
    return new;
  end if;

  v_kickoff := (new.match_date + new.match_time) at time zone 'Europe/Paris';

  -- Un Live terminé suffit : le coach a pu lancer et finir le match avant
  -- l'heure prévue (même règle que la validation du compte rendu).
  if new.status = 'termine'
     and v_kickoff > now()
     and not exists (
       select 1
       from public.match_live_sessions live_session
       where live_session.match_id = new.id
         and live_session.state = 'finished'
     ) then
    raise exception 'Un match futur ne peut pas être marqué terminé : termine d’abord son Live.'
      using errcode = '22023';
  end if;

  return new;
end;
$$;

do $migration$
declare
  v_function record;
  v_definition text;
  v_patched text;
  v_pair record;
begin
  create temporary table live_message_fr (english text primary key, french text not null)
    on commit drop;
  insert into live_message_fr (english, french) values
    ('A coach cannot be added to the live lineup', 'Un coach ne peut pas être ajouté à la composition du Live.'),
    ('A field/bench change was not declared as a substitution', 'Un passage entre terrain et banc doit se faire par un changement.'),
    ('A goal minute must be between 0 and 90', 'La minute d’un but doit être comprise entre 0 et 90.'),
    ('A lineup cannot contain more than 11 starters', 'Une composition ne peut pas avoir plus de 11 titulaires.'),
    ('A match cannot have more than eleven actual starters', 'Un match ne peut pas avoir plus de 11 titulaires.'),
    ('A participant can appear only once', 'Un joueur ne peut apparaître qu’une seule fois.'),
    ('A player cannot appear twice in the same substitution batch', 'Un joueur ne peut pas apparaître deux fois dans le même changement.'),
    ('A score of zero cannot contain scorers', 'Un score de zéro ne peut pas avoir de buteur.'),
    ('A scorer or assist must be part of the match squad', 'Le buteur ou le passeur doit faire partie de l’effectif du match.'),
    ('A selected player is already present in the live lineup', 'Un des joueurs choisis est déjà dans la composition du Live.'),
    ('Active administrator role or validated Live coach context required', 'Action réservée à l’administrateur ou au coach du Live.'),
    ('Active administrator role required', 'Action réservée à l’administrateur.'),
    ('Active authenticated session required', 'Ta session a expiré. Reconnecte-toi.'),
    ('Active profile required', 'Ton compte n’est pas actif. Reconnecte-toi ou contacte l’administrateur.'),
    ('An assist requires a different scorer', 'Le passeur doit être différent du buteur.'),
    ('An assist requires a scorer', 'Une passe décisive demande un buteur.'),
    ('An opponent goal cannot be credited to an AS Grinta player', 'Un but adverse ne peut pas être attribué à un joueur de ton équipe.'),
    ('An own goal cannot be credited to a player', 'Un but contre son camp ne peut pas être attribué à un joueur.'),
    ('An own goal cannot have an assist', 'Un but contre son camp ne peut pas avoir de passeur.'),
    ('At least one present participant is required', 'Il faut au moins un joueur présent.'),
    ('Attributed assists exceed the AS Grinta score', 'Il y a plus de passes décisives que de buts marqués par ton équipe.'),
    ('Attributed goals exceed the AS Grinta score', 'Il y a plus de buts attribués que de buts marqués par ton équipe.'),
    ('Authentication required', 'Ta session a expiré. Reconnecte-toi.'),
    ('Authentication session required', 'Ta session a expiré. Reconnecte-toi.'),
    ('Clean sheet is impossible when the opponent scored', 'Un clean sheet est impossible si l’adversaire a marqué.'),
    ('Clean sheet must belong to a present goalkeeper', 'Le clean sheet doit revenir à un gardien présent.'),
    ('Clean sheet must belong to an active goalkeeper in the match season', 'Le clean sheet doit revenir à un gardien de la saison du match.'),
    ('Coach or administrator role required', 'Action réservée au coach ou à l’administrateur.'),
    ('Coach, administrator or moderator role required', 'Action réservée au coach, à l’administrateur ou au modérateur.'),
    ('Each scorer entry must be an object', 'La liste des buteurs est mal formée. Recharge l’écran.'),
    ('Enabled flag is required', 'Le choix activé ou désactivé est obligatoire.'),
    ('End the live match before publishing its report', 'Termine le Live avant de valider le compte rendu.'),
    ('End the match before exporting its recap', 'Termine le match avant d’exporter le compte rendu.'),
    ('Event not found', 'Cet événement du match est introuvable. Recharge l’écran.'),
    ('Every eligible participant must appear exactly once', 'Chaque joueur convoqué doit apparaître une seule fois. Recharge l’écran.'),
    ('Every match participant must appear exactly once', 'Chaque joueur du match doit apparaître une seule fois. Recharge l’écran.'),
    ('Every starter needs a position on the pitch', 'Chaque titulaire doit avoir une place sur le terrain.'),
    ('Expected lineup revision is required', 'La version de la composition manque. Recharge l’écran.'),
    ('Final presence, role and statistics are inconsistent', 'Les présences, rôles et statistiques ne sont pas cohérents.'),
    ('Finalization contains an unknown participant', 'Le compte rendu contient un joueur inconnu. Recharge l’écran.'),
    ('Formation code cannot exceed 32 characters', 'Le dispositif ne peut pas dépasser 32 caractères.'),
    ('Goal actions payload must be a JSON array', 'La liste des buts est mal formée. Recharge l’écran.'),
    ('Goal notifications are not available for this match', 'Les notifications de but ne sont pas disponibles pour ce match.'),
    ('Guest first name is required', 'Le prénom de l’invité est obligatoire.'),
    ('Guest name cannot exceed 80 characters per field', 'Le nom de l’invité ne peut pas dépasser 80 caractères par champ.'),
    ('Guest player identifier is required', 'L’invité à ajouter manque. Recharge l’écran.'),
    ('Guest player is unavailable or archived', 'Cet invité n’est plus disponible.'),
    ('Half-time is only available during the first half', 'La mi-temps n’est possible que pendant la première période.'),
    ('Idempotency command unavailable', 'Action momentanément indisponible. Réessaie.'),
    ('Invalid clock action', 'Action sur le chrono inconnue.'),
    ('Invalid delivery counters', 'Compteurs d’envoi invalides.'),
    ('Invalid final participant entry', 'Une ligne du compte rendu est invalide. Recharge l’écran.'),
    ('Invalid formation code', 'Ce dispositif n’existe pas.'),
    ('Invalid goal action entry', 'Un but du compte rendu est invalide. Recharge l’écran.'),
    ('Invalid guest player identifier', 'Cet invité est introuvable. Recharge l’écran.'),
    ('Invalid lineup entry', 'Une ligne de la composition est invalide. Recharge l’écran.'),
    ('Invalid lineup zone or coordinates', 'Une place sur le terrain est invalide. Recharge l’écran.'),
    ('Invalid roster player identifier', 'Ce joueur est introuvable. Recharge l’écran.'),
    ('Invalid scorer entry schema', 'La liste des buteurs est mal formée. Recharge l’écran.'),
    ('Invalid scorer entry types', 'La liste des buteurs est mal formée. Recharge l’écran.'),
    ('Invalid scorer entry values', 'La liste des buteurs contient une valeur invalide.'),
    ('Invalid substitution payload', 'Ce changement est invalide. Recharge l’écran.'),
    ('Invalid team', 'Équipe inconnue pour ce but.'),
    ('Lineup entries must be a JSON array', 'La composition est mal formée. Recharge l’écran.'),
    ('Lineup payload must carry a JSON array of entries', 'La composition est mal formée. Recharge l’écran.'),
    ('Live composition not found', 'La composition du Live est introuvable. Recharge l’écran.'),
    ('Live lineup entries cannot use the available zone', 'Pendant le Live, un joueur est sur le terrain ou sur le banc.'),
    ('Live lineup is missing a promoted player', 'Un joueur convoqué entre-temps manque dans la composition. Recharge l’écran.'),
    ('Live lineup is stale after a convocation change', 'Les convocations ont changé entre-temps. Recharge l’écran avant de démarrer.'),
    ('Live session not found', 'Le Live de ce match est introuvable. Recharge l’écran.'),
    ('Live tracking is only available for upcoming matches', 'Le Live n’est disponible que pour les matchs à venir.'),
    ('Match composition not found', 'La composition du match est introuvable.'),
    ('Match id is required', 'Le match est obligatoire.'),
    ('Match kickoff is required', 'L’heure du coup d’envoi est obligatoire.'),
    ('Match not found', 'Ce match est introuvable ou a été supprimé.'),
    ('No live session for this match', 'Le Live de ce match n’a pas encore été ouvert.'),
    ('Only a finished (not yet exported) match can be reopened', 'Seul un match terminé et pas encore validé peut être rouvert.'),
    ('Only an AS Grinta goal can have a scorer', 'Seul un but de ton équipe peut avoir un buteur.'),
    ('Only one goalkeeper can receive the clean sheet', 'Un seul gardien peut recevoir le clean sheet.'),
    ('Only upcoming or finished matches can be validated', 'Seul un match à venir ou terminé peut être validé.'),
    ('Open the live workspace before adding a player', 'Ouvre le Live avant d’ajouter un joueur.'),
    ('Open the live workspace before starting the match', 'Ouvre le Live avant de démarrer le match.'),
    ('Operation id already used for another score command', 'Cette action sur le score a déjà été envoyée. Recharge l’écran.'),
    ('Operation id is required', 'Action sur le score incomplète. Réessaie.'),
    ('Participants payload must be a JSON array', 'La liste des joueurs est mal formée. Recharge l’écran.'),
    ('Player kind must be roster, guest or new_guest', 'Type de joueur inconnu.'),
    ('Players can only be added while the live session is open', 'Les joueurs ne peuvent être ajoutés que pendant le Live.'),
    ('Players must be a non-empty JSON array of at most 30 items', 'Choisis entre 1 et 30 joueurs à ajouter.'),
    ('Reason cannot exceed 500 characters', 'La raison ne peut pas dépasser 500 caractères.'),
    ('Roster player identifier is required', 'Le joueur à ajouter manque. Recharge l’écran.'),
    ('Roster player is not active for this match season', 'Ce joueur ne fait pas partie de l’effectif de la saison du match.'),
    ('Score delta must be -1 or 1', 'Le score ne change que d’un but à la fois.'),
    ('Scorer goals must be between 1 and 99', 'Le nombre de buts d’un buteur doit être compris entre 1 et 99.'),
    ('Scorer is not an active player in the match season', 'Ce buteur ne fait pas partie de l’effectif de la saison du match.'),
    ('Scorers payload must be a JSON array', 'La liste des buteurs est mal formée. Recharge l’écran.'),
    ('Scores must be between 0 and 99', 'Le score doit être compris entre 0 et 99.'),
    ('Sport match workflow not found', 'Le suivi sportif de ce match est introuvable.'),
    ('Substitution must bring in a non-field player and remove a field player', 'Un changement fait entrer un joueur du banc et sortir un joueur du terrain.'),
    ('The assist cannot be credited to the scorer', 'Le passeur doit être différent du buteur.'),
    ('The clock is not paused', 'Le chrono n’est pas en pause.'),
    ('The clock is not running', 'Le chrono n’est pas lancé.'),
    ('The incoming player must end up on the field', 'Le joueur qui entre doit finir sur le terrain.'),
    ('The lineup can only be edited while the live session is open', 'La composition ne peut changer que pendant le Live.'),
    ('The match cannot be finalized before kickoff', 'Démarre puis termine le match dans le Live avant de le valider.'),
    ('The match has already been started', 'Le match a déjà démarré.'),
    ('The match has not been started yet', 'Le match n’a pas encore démarré.'),
    ('The match is not at half-time', 'Le match n’est pas à la mi-temps.'),
    ('The match is not currently live', 'Le match n’est pas en cours.'),
    ('The report contains an unknown participant', 'Le compte rendu contient un joueur inconnu. Recharge l’écran.'),
    ('The score must match the recorded goals exactly', 'Le score doit correspondre exactement aux buts saisis.'),
    ('This match has already been exported', 'Le compte rendu de ce match est déjà validé.'),
    ('This match has already been exported and cannot be reopened', 'Le compte rendu de ce match est déjà validé : le Live ne peut plus être rouvert.'),
    ('Too many goal actions', 'Trop de buts dans le compte rendu.'),
    ('Too many scorer entries', 'Trop de buteurs dans le compte rendu.'),
    ('Unknown assist provider for this match', 'Ce passeur ne fait pas partie de ce match.'),
    ('Unknown scorer for this match', 'Ce buteur ne fait pas partie de ce match.');

  for v_function in
    select p.oid
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname in ('public', 'private')
      and p.prokind = 'f'
      and (
        p.proname ~ 'live'
        or p.proname in (
          'submit_match_sport_report',
          'admin_submit_match_sport_report',
          'finalize_match_sport_postgame',
          'admin_finalize_match_sport_postgame',
          'finalize_match_postgame'
        )
      )
  loop
    v_definition := pg_get_functiondef(v_function.oid);
    v_patched := v_definition;
    for v_pair in select english, french from live_message_fr loop
      v_patched := replace(
        v_patched,
        quote_literal(v_pair.english),
        quote_literal(v_pair.french)
      );
    end loop;
    if v_patched is distinct from v_definition then
      execute v_patched;
    end if;
  end loop;
end;
$migration$;
