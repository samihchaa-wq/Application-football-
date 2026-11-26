-- Jeton interne signé par usage et par club.
--
-- Avant : la base envoyait le même mot de passe interne (`push_internal_token`)
-- à toutes ses fonctions serveur, pour tous les clubs. Une requête interceptée
-- permettait donc d'envoyer des notifications à n'importe quel club, ou de
-- lancer la suppression des comptes inactifs.
--
-- Désormais, chaque appel sortant porte en plus une signature
-- (`x-push-signature`), calculée à partir du mot de passe interne, du nom de
-- la fonction appelée et du club concerné. Les fonctions serveur ne croient
-- plus que cette signature : une signature volée ne sert que pour une seule
-- fonction et un seul club.
--
-- Transition sans coupure : le mot de passe brut (`x-push-token`) est encore
-- envoyé, le temps que les nouvelles fonctions serveur soient publiées (elles
-- le sont juste après les migrations). Une migration suivante le retirera.

create extension if not exists pgcrypto with schema extensions;

-- Signature d'un appel interne : HMAC-SHA256 du texte « fonction|club » avec
-- le mot de passe interne comme clé, en hexadécimal. Sans club, la partie
-- club est vide (ex. tâche de nuit des comptes inactifs). Le même calcul est
-- fait côté serveur (supabase/functions/_shared/internal_call.ts).
create or replace function private.internal_call_signature(
  p_token text,
  p_function text,
  p_club text
) returns text
language sql immutable
set search_path to ''
as $$
  select encode(
    extensions.hmac(
      p_function || '|' || coalesce(p_club, ''),
      p_token,
      'sha256'
    ),
    'hex'
  );
$$;

-- Fonction de calcul pure, sans accès aux données. Elle reste à postgres,
-- comme private.http_post qui l'appelle hors du cloisonnement.
revoke all on function private.internal_call_signature(text, text, text) from public, anon, authenticated;

-- Même fonction qu'avant (20261112000000_push_et_fichiers_par_club.sql), avec
-- en plus la signature quand l'appel porte le mot de passe interne et vise une
-- fonction serveur du projet.
create or replace function private.http_post(
  url text,
  body jsonb default '{}'::jsonb,
  params jsonb default '{}'::jsonb,
  headers jsonb default '{"Content-Type": "application/json"}'::jsonb,
  timeout_milliseconds integer default 5000
) returns bigint
language plpgsql security definer
set search_path to ''
as $$
declare
  v_headers jsonb := coalesce(headers, '{}'::jsonb);
  v_club uuid := private.current_club_id();
  v_function text;
begin
  -- Un en-tête déjà fourni par l'appelant est conservé tel quel.
  if v_club is not null and not (v_headers ? 'x-club-id') then
    v_headers := v_headers || jsonb_build_object('x-club-id', v_club::text);
  end if;

  if coalesce(v_headers ->> 'x-push-token', '') <> '' then
    v_function := substring(url from '/functions/v1/([A-Za-z0-9_-]+)');
    if v_function is not null then
      v_headers := v_headers || jsonb_build_object(
        'x-push-signature',
        private.internal_call_signature(
          v_headers ->> 'x-push-token',
          v_function,
          v_headers ->> 'x-club-id'
        )
      );
    end if;
  end if;

  return net.http_post(
    url := url,
    body := body,
    params := params,
    headers := v_headers,
    timeout_milliseconds := timeout_milliseconds
  );
end;
$$;

revoke all on function private.http_post(text, jsonb, jsonb, jsonb, integer) from public;
grant execute on function private.http_post(text, jsonb, jsonb, jsonb, integer) to club_scope;
