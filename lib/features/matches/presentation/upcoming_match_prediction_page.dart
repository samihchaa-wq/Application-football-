import 'package:petit_filet/core/theme/app_spacing.dart';
import 'package:petit_filet/core/widgets/pf_app_bar.dart';
import 'package:petit_filet/features/predictions/presentation/widgets/inline_match_prediction_card.dart';
import 'package:flutter/material.dart';

class UpcomingMatchPredictionPage extends StatelessWidget {
  const UpcomingMatchPredictionPage({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PfAppBar(title: const Text('Ton prono')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenGutter,
          AppSpacing.sectionGap,
          AppSpacing.screenGutter,
          40,
        ),
        children: [InlineMatchPredictionCard(matchId: matchId)],
      ),
    );
  }
}
