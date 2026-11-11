-- Objets hors des schémas public/private et données de référence du produit.
-- Aucune donnée de club ici.

-- Création du profil à l'inscription.
create trigger on_auth_user_created
  after insert or update of email, raw_user_meta_data on auth.users
  for each row execute function public.handle_new_auth_user();

-- Espaces de stockage des fichiers.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values ('app-assets', 'app-assets', true, 10485760, array['image/png','image/jpeg','image/webp']) on conflict (id) do nothing;
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values ('badge-images', 'badge-images', true, 5242880, array['image/jpeg','image/png','image/webp']) on conflict (id) do nothing;
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types) values ('profile-photos', 'profile-photos', false, 5242880, array['image/jpeg','image/png','image/webp']) on conflict (id) do nothing;

-- Droits sur les fichiers.
CREATE POLICY "badge_images_admin_delete" ON "storage"."objects" FOR DELETE TO "authenticated" USING ((("bucket_id" = 'badge-images'::"text") AND ( SELECT "private"."can_manage_badges"() AS "can_manage_badges")));
CREATE POLICY "badge_images_admin_insert" ON "storage"."objects" FOR INSERT TO "authenticated" WITH CHECK ((("bucket_id" = 'badge-images'::"text") AND ( SELECT "private"."can_manage_badges"() AS "can_manage_badges")));
CREATE POLICY "badge_images_admin_update" ON "storage"."objects" FOR UPDATE TO "authenticated" USING ((("bucket_id" = 'badge-images'::"text") AND ( SELECT "private"."can_manage_badges"() AS "can_manage_badges"))) WITH CHECK ((("bucket_id" = 'badge-images'::"text") AND ( SELECT "private"."can_manage_badges"() AS "can_manage_badges")));
CREATE POLICY "profile_photos_active_read" ON "storage"."objects" FOR SELECT TO "authenticated" USING ((("bucket_id" = 'profile-photos'::"text") AND "private"."is_active_profile"()));
CREATE POLICY "profile_photos_admin_write" ON "storage"."objects" TO "authenticated" USING ((("bucket_id" = 'profile-photos'::"text") AND ( SELECT "private"."is_admin"() AS "is_admin"))) WITH CHECK ((("bucket_id" = 'profile-photos'::"text") AND ( SELECT "private"."is_admin"() AS "is_admin")));
CREATE POLICY "profile_photos_owner_delete" ON "storage"."objects" FOR DELETE TO "authenticated" USING ((("bucket_id" = 'profile-photos'::"text") AND ( SELECT "private"."is_active_profile"() AS "is_active_profile") AND ("owner_id" = (( SELECT "auth"."uid"() AS "uid"))::"text")));
CREATE POLICY "profile_photos_owner_insert" ON "storage"."objects" FOR INSERT TO "authenticated" WITH CHECK ((("bucket_id" = 'profile-photos'::"text") AND ( SELECT "private"."is_active_profile"() AS "is_active_profile") AND ("owner_id" = (( SELECT "auth"."uid"() AS "uid"))::"text") AND (("storage"."foldername"("name"))[1] = (( SELECT "auth"."uid"() AS "uid"))::"text")));
CREATE POLICY "profile_photos_owner_update" ON "storage"."objects" FOR UPDATE TO "authenticated" USING ((("bucket_id" = 'profile-photos'::"text") AND ( SELECT "private"."is_active_profile"() AS "is_active_profile") AND ("owner_id" = (( SELECT "auth"."uid"() AS "uid"))::"text"))) WITH CHECK ((("bucket_id" = 'profile-photos'::"text") AND ( SELECT "private"."is_active_profile"() AS "is_active_profile") AND ("owner_id" = (( SELECT "auth"."uid"() AS "uid"))::"text") AND (("storage"."foldername"("name"))[1] = (( SELECT "auth"."uid"() AS "uid"))::"text")));

-- Tables diffusées en temps réel.
alter publication supabase_realtime add table public.feature_flag_change_signals;
alter publication supabase_realtime add table public.match_live_events;
alter publication supabase_realtime add table public.match_live_sessions;
alter publication supabase_realtime add table public.match_weather;
alter publication supabase_realtime add table public.shared_data_change_signals;

-- Tâches planifiées.
select cron.schedule('waitlist-credit', '* * * * *', $cron$select private.process_due_waitlist_credits();$cron$);
select cron.schedule('badge-unlock-notifications', '* * * * *', $cron$select private.process_badge_unlock_notifications(now());$cron$);
select cron.schedule('finish-due-internal-matches', '* * * * *', $cron$select private.finish_due_internal_matches(now());$cron$);
select cron.schedule('live-match-notification-dispatch', '5 seconds', $cron$select private.process_due_match_live_notifications(50);$cron$);
select cron.schedule('match-weather-refresh', '*/15 * * * *', $cron$select private.request_match_weather_refresh(null);$cron$);
select cron.schedule('prediction-j5-reminders', '* * * * *', $cron$select public.push_prediction_j5_notifications();$cron$);
select cron.schedule('process-season-wrapped-jobs', '*/5 * * * *', $cron$select private.process_season_wrapped_jobs();$cron$);
select cron.schedule('purge-client-incident-log', '17 3 * * *', $cron$select private.purge_client_incident_log(now());$cron$);
select cron.schedule('purge-cron-job-run-details', '23 3 * * *', $cron$delete from cron.job_run_details where end_time < now() - interval '7 days'$cron$);
select cron.schedule('sports-availability-reminders', '* * * * *', $cron$select private.process_sport_availability_notifications(now());$cron$);
select cron.schedule('sports-motm-jobs', '* * * * *', $cron$select private.process_match_motm_jobs(now());$cron$);


-- Donnée de référence commune à tous les clubs.
insert into private.sport_waitlist_engine_activation(singleton) values(true) on conflict (singleton) do nothing;
