/// Sous-fonctionnalités réglables par club. Les libellés et les bornes
/// viennent du catalogue serveur ; ces défauts préservent les anciens clubs.
enum ClubFeature {
  liveSubstitutions('live_substitutions', true, 'live'),
  liveFormationChanges('live_formation_changes', true, 'live'),
  liveAddPlayers('live_add_players', true, 'live'),
  liveRemovePlayers('live_remove_players', true, 'live'),
  liveScorers('live_scorers', true, 'live'),
  liveAssists('live_assists', true, 'live'),
  liveOwnGoals('live_own_goals', true, 'live'),
  liveEventDeletion('live_event_deletion', true, 'live'),
  liveRestart('live_restart', true, 'live'),
  liveTakeover('live_takeover', true, 'live'),
  livePause('live_pause', true, 'live'),
  liveShowPlayingTime('live_show_playing_time', true, 'live'),
  liveShowBenchCounts('live_show_bench_counts', true, 'live'),
  liveNextOut('live_next_out', true, 'live'),
  liveNamesOnly('live_names_only', false, 'live'),
  liveJournalExpanded('live_journal_expanded', false, 'live'),
  liveSubstitutionColors('live_substitution_colors', true, 'live'),
  compositionSimulation('composition_simulation', true, 'composition'),
  compositionVideo('composition_video', true, 'composition'),
  compositionVideoAutoplay('composition_video_autoplay', true, 'composition'),
  compositionVideoNotificationReplay(
    'composition_video_notification_replay',
    true,
    'composition',
  ),
  notifyAvailabilityJ3('notify_availability_j3', true, 'squad'),
  notifyAvailabilityJ1('notify_availability_j1', true, 'squad'),
  notifyLiveFullTime('notify_live_full_time', true, 'live'),
  notifyLiveGoalUs('notify_live_goal_us', true, 'live'),
  notifyLiveGoalThem('notify_live_goal_them', true, 'live'),
  notifyMatchCancelled('notify_match_cancelled', true, 'matches'),
  notifyMatchRescheduledDate('notify_match_rescheduled_date', true, 'matches'),
  notifyMatchRescheduledTime('notify_match_rescheduled_time', true, 'matches'),
  notifyConvocationPromoted('notify_convocation_promoted', true, 'squad'),
  notifyConvocationDemoted('notify_convocation_demoted', true, 'squad'),
  notifyMotmWinner('notify_motm_winner', true, 'rewards');

  const ClubFeature(this.key, this.defaultEnabled, this.section);
  final String key;
  final bool defaultEnabled;
  final String section;

  static ClubFeature? forKey(String key) {
    for (final feature in values) {
      if (feature.key == key) return feature;
    }
    return null;
  }
}
