-- Refonte des badges pour un produit multi-clubs.
--
-- 1. La gestion des badges (créer, renommer, images) était réservée à deux
--    comptes précis du club d'origine. Elle revient à tout administrateur
--    actif, pour son propre club : les règles de cloisonnement par club
--    l'empêchent d'agir sur un autre club.
-- 2. Les noms qui ne parlent qu'au club d'origine, ou qui reprennent des
--    récompenses protégées (« Ballon d'or », « Soulier d'or »), sont remplacés
--    par des noms neutres. Les règles d'attribution ne changent pas.

create or replace function private.can_manage_badges() returns boolean
language sql stable security definer
set search_path to ''
as $$
  select
    coalesce(private.jwt() ->> 'role' = 'service_role', false)
    or exists (
      select 1
      from public.profiles p
      where p.id = private.uid()
        and p.status = 'active'
        and p.role = 'admin'
    );
$$;

create temporary table badge_renames (
  code text primary key,
  name text not null,
  description text
) on commit drop;

insert into badge_renames (code, name, description) values
  ('mvp__50', 'Icône du club', null),
  ('title_top_scorer__1', 'Meilleur buteur', null),
  ('title_mvp_king__1', 'Joueur de la saison', null),
  ('title_top_assists__1', 'Meilleur passeur', null),
  ('role_president', 'Président', null),
  ('bet_against_grinta__1', 'Avocat du diable',
   'Pronostiquer contre son propre club… et avoir raison.'),
  ('exploit_but_vainqueur_tardif', 'Buteur décisif', null),
  ('exploit_csc', 'Contre son camp', null),
  ('exploit_penalty_provoque', 'Penalty concédé', null),
  ('exploit_penalty_subi', 'Penalty obtenu', null);

update private.badge_templates t
set name = r.name, description = coalesce(r.description, t.description)
from badge_renames r
where t.code = r.code;

-- Les clubs déjà créés reçoivent les mêmes noms, sauf s'ils ont renommé le
-- badge eux-mêmes.
update public.badges b
set name = r.name, description = coalesce(r.description, b.description)
from badge_renames r
join (
  select code, name as old_name from (values
    ('mvp__50', 'Mobutu'),
    ('title_top_scorer__1', 'Soulier d’or'),
    ('title_mvp_king__1', 'Ballon d’or'),
    ('title_top_assists__1', 'Passe d’or'),
    ('role_president', 'El Presidente'),
    ('bet_against_grinta__1', 'Traître'),
    ('exploit_but_vainqueur_tardif', 'Clutch'),
    ('exploit_csc', 'La Boulette'),
    ('exploit_penalty_provoque', 'Le Boucher'),
    ('exploit_penalty_subi', 'Le Plongeur')
  ) v(code, name)
) o on o.code = r.code
where b.code = r.code and b.name = o.old_name;
