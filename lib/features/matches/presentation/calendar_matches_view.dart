import 'package:petit_filet/core/utils/club_time.dart';
import 'package:petit_filet/core/club/club_identity.dart';
import 'dart:math' as math;

import 'package:petit_filet/app/shell/module_navigation.dart';
import 'package:petit_filet/core/utils/app_errors.dart';
import 'package:petit_filet/core/theme/app_spacing.dart';
import 'package:petit_filet/core/theme/app_theme.dart';
import 'package:petit_filet/core/theme/calendar_card_palette.dart';
import 'package:petit_filet/core/theme/pf_card_border.dart';
import 'package:petit_filet/core/utils/match_window.dart';
import 'package:petit_filet/core/widgets/calendar_scoreline.dart';
import 'package:petit_filet/core/widgets/pf_empty_state.dart';
import 'package:petit_filet/core/widgets/pf_loader.dart';
import 'package:petit_filet/core/widgets/match_address_sheet.dart';
import 'package:petit_filet/features/auth/presentation/auth_state.dart';
import 'package:petit_filet/features/match_live/data/match_live_notification_repository.dart';
import 'package:petit_filet/features/match_live/presentation/widgets/match_live_notification_bell.dart';
import 'package:petit_filet/features/matches/data/calendar_history_repository.dart';
import 'package:petit_filet/features/matches/data/club_events_repository.dart';
import 'package:petit_filet/features/matches/domain/club_event.dart';
import 'package:petit_filet/features/matches/domain/match_model.dart';
import 'package:petit_filet/features/matches/presentation/calendar_entry_form_page.dart';
import 'package:petit_filet/features/matches/presentation/matches_controller.dart';
import 'package:petit_filet/features/matches/presentation/widgets/admin_match_options_button.dart';
import 'package:petit_filet/features/matches/presentation/widgets/calendar_actions_bar.dart';
import 'package:petit_filet/features/matches/presentation/widgets/historical_match_card.dart';
import 'package:petit_filet/features/predictions/presentation/merged_matches_view.dart';
import 'package:petit_filet/features/predictions/presentation/widgets/match_history_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'calendar_matches_widgets.dart';

enum _CalendarDisplayMode { scroll, month }

class CalendarMatchesView extends ConsumerStatefulWidget {
  const CalendarMatchesView({super.key, this.focusMatchId});

  /// Match sur lequel ouvrir le défilé, sinon le dernier match joué.
  final String? focusMatchId;

  @override
  ConsumerState<CalendarMatchesView> createState() =>
      _CalendarMatchesViewState();
}

class _CalendarMatchesViewState extends ConsumerState<CalendarMatchesView> {
  _CalendarDisplayMode _displayMode = _CalendarDisplayMode.scroll;
  DateTime _monthCursor = DateTime(ClubTime.now().year, ClubTime.now().month);
  final Map<String, Future<List<HistoricalMatchResult>>> _historyLoads = {};

  @override
  void didUpdateWidget(covariant CalendarMatchesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Un match demandé (notification de disponibilité) se montre dans le
    // défilé, où se trouve son sélecteur de présence.
    if (widget.focusMatchId != null &&
        widget.focusMatchId != oldWidget.focusMatchId &&
        _displayMode != _CalendarDisplayMode.scroll) {
      setState(() => _displayMode = _CalendarDisplayMode.scroll);
    }
  }

  Future<List<HistoricalMatchResult>> _historyForSeason(String seasonName) {
    return _historyLoads.putIfAbsent(
      seasonName,
      () => ref.read(calendarHistoryRepositoryProvider).fetchSeason(seasonName),
    );
  }

  Future<void> _refreshHistory(String seasonName) async {
    setState(() {
      _historyLoads[seasonName] =
          ref.read(calendarHistoryRepositoryProvider).fetchSeason(seasonName);
    });
    ref.invalidate(clubEventsProvider);
    await _historyLoads[seasonName];
  }

  Future<void> _refreshModernMatches() async {
    final state = ref.read(matchesControllerProvider);
    ref.invalidate(clubEventsProvider);
    ref.invalidate(allHistoricalMatchesProvider);
    await ref
        .read(matchesControllerProvider.notifier)
        .load(seasonId: state.selectedSeasonId, allSeasons: true);
  }

  Future<void> _openCreate() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CalendarEntryFormPage()),
    );
    if (!mounted || changed != true) return;
    await _refreshModernMatches();
  }

  void _selectSeason(String? seasonName, List<Map<String, dynamic>> seasons) {
    if (seasonName == null) return;
    final season = seasons.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item?['name']?.toString() == seasonName,
          orElse: () => null,
        );
    if (season == null) return;
    setState(() => _monthCursor = _initialMonthForSeason(season));
  }

  void _moveMonth(int delta, List<Map<String, dynamic>> seasons) {
    if (seasons.isEmpty) return;
    final candidate = DateTime(_monthCursor.year, _monthCursor.month + delta);
    final bounds = _monthBounds(seasons);
    if (bounds == null ||
        candidate.isBefore(bounds.$1) ||
        candidate.isAfter(bounds.$2)) {
      return;
    }
    setState(() => _monthCursor = candidate);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(matchesFocusRequestProvider, (previous, next) {
      if (_displayMode != _CalendarDisplayMode.month) return;
      final now = ClubTime.now();
      final currentMonth = DateTime(now.year, now.month);
      if (_monthCursor == currentMonth) return;
      setState(() => _monthCursor = currentMonth);
    });

    final state = ref.watch(matchesControllerProvider);
    final isAdmin = ref.watch(isAdminViewProvider);
    final events =
        ref.watch(clubEventsProvider).valueOrNull ?? const <ClubEvent>[];
    final seasons = [...state.seasons]
      ..sort((a, b) => b['name'].toString().compareTo(a['name'].toString()));
    final currentSeason = seasons.cast<Map<String, dynamic>?>().firstWhere(
          (season) => season?['status']?.toString() == 'open',
          orElse: () => null,
        );
    final currentSeasonName = currentSeason?['name']?.toString();
    final selectedSeason =
        _seasonForMonth(seasons, _monthCursor) ?? currentSeason;
    final selectedSeasonName = selectedSeason?['name']?.toString();
    final selectedSeasonId = selectedSeason?['id']?.toString();
    final bounds = _monthBounds(seasons);
    final canGoPrevious = bounds != null && _monthCursor.isAfter(bounds.$1);
    final canGoNext = bounds != null && _monthCursor.isBefore(bounds.$2);

    return Column(
      children: [
        _CalendarToolbar(
          displayMode: _displayMode,
          onCreate: isAdmin ? _openCreate : null,
          seasons: seasons,
          selectedSeasonName: selectedSeasonName,
          currentSeasonName: currentSeasonName,
          monthCursor: _monthCursor,
          canGoPrevious: canGoPrevious,
          canGoNext: canGoNext,
          onSeasonChanged: (value) => _selectSeason(value, seasons),
          onPreviousMonth: () => _moveMonth(-1, seasons),
          onNextMonth: () => _moveMonth(1, seasons),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = math.min(constraints.maxWidth, 1120.0);
              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: contentWidth,
                  height: constraints.maxHeight,
                  child: IndexedStack(
                    index: _displayMode == _CalendarDisplayMode.scroll ? 0 : 1,
                    children: [
                      MergedMatchesView(focusMatchId: widget.focusMatchId),
                      _buildMonthView(
                        state: state,
                        selectedSeason: selectedSeason,
                        selectedSeasonName: selectedSeasonName,
                        selectedSeasonId: selectedSeasonId,
                        events: events,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMonthView({
    required MatchesState state,
    required Map<String, dynamic>? selectedSeason,
    required String? selectedSeasonName,
    required String? selectedSeasonId,
    required List<ClubEvent> events,
  }) {
    if (state.isLoading && state.seasons.isEmpty) {
      return const Center(child: PfProgressIndicator());
    }
    if (state.error != null && state.seasons.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenGutter),
        children: [
          PfEmptyState(
            icon: Icons.wifi_off_outlined,
            title: 'Calendrier indisponible',
            message: state.error!,
            tone: PfEmptyTone.alert,
          ),
        ],
      );
    }
    if (selectedSeason == null ||
        selectedSeasonName == null ||
        selectedSeasonId == null) {
      return const _MonthEmptyState(
        title: 'Aucune saison disponible',
      );
    }

    final modernMatches = state.matches
        .where((match) => match.seasonId == selectedSeasonId)
        .toList(growable: false);
    final seasonEvents = events
        .where((event) => event.seasonId == selectedSeasonId)
        .toList(growable: false);
    final isOpenSeason = selectedSeason['status']?.toString() == 'open';
    final usesModernMatches = isOpenSeason || modernMatches.isNotEmpty;

    if (usesModernMatches) {
      return _ModernMonthView(
        month: _monthCursor,
        seasonName: selectedSeasonName,
        matches: modernMatches,
        events: seasonEvents,
        onRefresh: _refreshModernMatches,
      );
    }

    return _HistoricalMonthView(
      month: _monthCursor,
      seasonName: selectedSeasonName,
      future: _historyForSeason(selectedSeasonName),
      events: seasonEvents,
      onRefresh: () => _refreshHistory(selectedSeasonName),
    );
  }
}
