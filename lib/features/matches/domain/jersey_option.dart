import 'package:as_grinta/core/club/club_kits.dart';

/// Identifiant stable d'une tenue. Les trois identifiants historiques restent
/// lisibles, mais les clubs peuvent désormais ajouter des tenues libres.
class JerseyOption {
  const JerseyOption._(this.id);

  static const france = JerseyOption._('france');
  static const orange = JerseyOption._('orange');
  static const blue = JerseyOption._('blue');

  final String id;

  static final RegExp _customId = RegExp(r'^kit_[a-z0-9_]{1,48}$');

  /// Inclut les identifiants historiques pour décoder les anciens matchs.
  /// Les nouvelles tenues utilisent un identifiant stable par club.
  static List<JerseyOption> get values => [
        france,
        orange,
        blue,
        for (final kit in ClubKits.all)
          if (kit.slot != france && kit.slot != orange && kit.slot != blue)
            kit.slot,
      ];

  ClubKit get kit => ClubKits.of(this);
  String get label => kit.label;

  static JerseyOption? fromId(String? id) {
    if (id == null) return null;
    if (id == france.id) return france;
    if (id == orange.id) return orange;
    if (id == blue.id) return blue;
    return _customId.hasMatch(id) ? JerseyOption._(id) : null;
  }

  @override
  bool operator ==(Object other) => other is JerseyOption && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'JerseyOption($id)';
}
