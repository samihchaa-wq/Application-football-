-- « Buteur décisif » (exploit_but_vainqueur_tardif) fait doublon avec
-- « Clutch » (custom_clutch_…) : même description (but de la victoire dans les
-- dernières minutes). Seul « Clutch » est décerné automatiquement ; l'autre
-- restait manuel et prêtait à confusion. On garde « Clutch ».

-- Futurs clubs : le modèle disparaît.
delete from private.badge_templates
where code = 'exploit_but_vainqueur_tardif';

-- Clubs existants : suppression seulement si personne ne l'a gagné.
-- Sinon on le laisse (la suppression effacerait des badges déjà attribués).
delete from public.badges b
where b.code = 'exploit_but_vainqueur_tardif'
  and not exists (
    select 1 from public.profile_badges pb where pb.badge_id = b.id
  );
