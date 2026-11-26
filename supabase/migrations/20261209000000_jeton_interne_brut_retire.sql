-- Fin de la transition du jeton interne (suite de
-- 20261208000000_jeton_interne_signe_par_usage_et_club.sql).
--
-- Les fonctions serveur publiées ne croient plus que la signature
-- (`x-push-signature`), propre à une fonction et à un club. Le mot de passe
-- interne brut (`x-push-token`) n'était plus envoyé que pour ne pas couper les
-- anciennes fonctions pendant leur publication : il ne quitte plus la base.
-- Une requête interceptée ne contient donc plus de quoi signer d'autres appels.

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

  -- Le mot de passe brut ne part jamais, même vers une adresse inattendue.
  v_headers := v_headers - 'x-push-token';

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
