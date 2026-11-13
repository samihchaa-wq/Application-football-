import 'package:as_grinta/core/theme/app_theme.dart';
import 'package:as_grinta/features/matches/domain/jersey_option.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Un maillot du club : son nom, ses deux couleurs et s'il est proposé.
@immutable
class ClubKit {
  const ClubKit({
    required this.slot,
    required this.label,
    required this.body,
    required this.trim,
    this.goalkeeperBody = const Color(0xFF168A52),
    this.goalkeeperTrim = const Color(0xFFFFFFFF),
    required this.enabled,
  });

  /// Emplacement technique (jamais affiché) : relie le maillot aux matchs déjà
  /// enregistrés et aux photos de maillot des joueurs.
  final JerseyOption slot;
  final String label;

  /// Couleur du corps du maillot.
  final Color body;

  /// Couleur des manches et du col.
  final Color trim;

  /// Couleurs du gardien distinctes de celles des joueurs de champ.
  final Color goalkeeperBody;
  final Color goalkeeperTrim;
  final bool enabled;

  ClubKit copyWith({
    String? label,
    Color? body,
    Color? trim,
    Color? goalkeeperBody,
    Color? goalkeeperTrim,
    bool? enabled,
  }) =>
      ClubKit(
        slot: slot,
        label: label ?? this.label,
        body: body ?? this.body,
        trim: trim ?? this.trim,
        goalkeeperBody: goalkeeperBody ?? this.goalkeeperBody,
        goalkeeperTrim: goalkeeperTrim ?? this.goalkeeperTrim,
        enabled: enabled ?? this.enabled,
      );

  Map<String, Object> toJson() => {
        'slot': slot.id,
        'label': label.trim(),
        'body': colorToHex(body),
        'trim': colorToHex(trim),
        'goalkeeper_body': colorToHex(goalkeeperBody),
        'goalkeeper_trim': colorToHex(goalkeeperTrim),
        'enabled': enabled,
      };

  @override
  bool operator ==(Object other) =>
      other is ClubKit &&
      other.slot == slot &&
      other.label == label &&
      other.body == body &&
      other.trim == trim &&
      other.goalkeeperBody == goalkeeperBody &&
      other.goalkeeperTrim == goalkeeperTrim &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(
        slot,
        label,
        body,
        trim,
        goalkeeperBody,
        goalkeeperTrim,
        enabled,
      );
}

/// « Color(0xFFAA0000) » → « #AA0000 ».
String colorToHex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// Les trois maillots du club du compte connecté.
///
/// Tenus ici, comme le nom du club ([ClubIdentity]), parce qu'ils s'affichent
/// dans plusieurs écrans (formulaire de match, fiche du match, compositions
/// « entre nous »). Tant que le club n'a rien réglé, des maillots par défaut
/// sont tirés de ses couleurs.
abstract final class ClubKits {
  static const int maxLabelLength = 20;

  static Color defaultGoalkeeperBodyFor(JerseyOption slot) => switch (slot) {
        JerseyOption.france => const Color(0xFF168A52),
        JerseyOption.orange => const Color(0xFFF5A300),
        JerseyOption.blue => const Color(0xFF1F6FEB),
      };

  static Color defaultGoalkeeperTrimFor(JerseyOption slot) =>
      const Color(0xFFFFFFFF);

  static final ValueNotifier<int> _revision = ValueNotifier<int>(0);
  static List<ClubKit>? _saved;
  static Color? _clubPrimary;
  static Color? _clubSecondary;

  /// Change à chaque mise à jour des maillots.
  static ValueListenable<int> get revision => _revision;

  /// Maillots proposés par défaut, à partir des couleurs du club (ou des
  /// couleurs neutres de l'application s'il n'en a pas choisi).
  static List<ClubKit> defaultsFor({Color? primary, Color? secondary}) {
    final main = primary ?? AppTheme.defaultPrimary;
    final second = secondary ?? const Color(0xFFFFFFFF);
    return [
      ClubKit(
        slot: JerseyOption.france,
        label: 'Domicile',
        body: main,
        trim: second,
        goalkeeperBody: defaultGoalkeeperBodyFor(JerseyOption.france),
        goalkeeperTrim: defaultGoalkeeperTrimFor(JerseyOption.france),
        enabled: true,
      ),
      ClubKit(
        slot: JerseyOption.orange,
        label: 'Extérieur',
        body: const Color(0xFFFFFFFF),
        trim: main,
        goalkeeperBody: defaultGoalkeeperBodyFor(JerseyOption.orange),
        goalkeeperTrim: defaultGoalkeeperTrimFor(JerseyOption.orange),
        enabled: true,
      ),
      ClubKit(
        slot: JerseyOption.blue,
        label: 'Troisième',
        body: const Color(0xFF1B1F2A),
        trim: second,
        goalkeeperBody: defaultGoalkeeperBodyFor(JerseyOption.blue),
        goalkeeperTrim: defaultGoalkeeperTrimFor(JerseyOption.blue),
        enabled: true,
      ),
    ];
  }

  /// Les trois maillots, dans l'ordre des emplacements.
  static List<ClubKit> get all =>
      _saved ?? defaultsFor(primary: _clubPrimary, secondary: _clubSecondary);

  /// Vrai quand le club n'a encore rien réglé.
  static bool get usesDefaults => _saved == null;

  /// Les maillots que l'administrateur propose pour un match.
  static List<ClubKit> get enabled => [
        for (final kit in all)
          if (kit.enabled) kit
      ];

  /// Les maillots au choix pour un match « entre nous », où il en faut deux
  /// différents : si le club n'en propose qu'un, les trois restent au choix.
  static List<ClubKit> get forInternalMatch {
    final list = enabled;
    return list.length >= 2 ? list : all;
  }

  static ClubKit of(JerseyOption slot) =>
      all.firstWhere((kit) => kit.slot == slot);

  /// Retient les couleurs du club, qui servent aux maillots par défaut.
  static void setClubColors({Color? primary, Color? secondary}) {
    if (primary == _clubPrimary && secondary == _clubSecondary) return;
    _clubPrimary = primary;
    _clubSecondary = secondary;
    if (_saved == null) _revision.value += 1;
  }

  /// Applique les maillots lus en base (`clubs.kits`). Une valeur absente ou
  /// illisible ramène aux maillots par défaut.
  static void setFromJson(Object? json) {
    final next = parse(json);
    if (listEquals(next, _saved)) return;
    _saved = next;
    _revision.value += 1;
  }

  static void reset() {
    _saved = null;
    _clubPrimary = null;
    _clubSecondary = null;
    _revision.value += 1;
  }

  /// Lit les maillots enregistrés. Renvoie null si la valeur ne décrit pas
  /// exactement les trois emplacements : rien ne doit casser l'affichage.
  static List<ClubKit>? parse(Object? json) {
    if (json is! List || json.length != JerseyOption.values.length) {
      return null;
    }
    final bySlot = <JerseyOption, ClubKit>{};
    for (final item in json) {
      if (item is! Map) return null;
      final slot = JerseyOption.fromId(item['slot']?.toString());
      if (slot == null) return null;
      final body = AppTheme.parseHex(item['body']?.toString());
      final trim = AppTheme.parseHex(item['trim']?.toString());
      // Les maillots antérieurs restent lisibles grâce à ces valeurs stables.
      final goalkeeperBody = item.containsKey('goalkeeper_body')
          ? AppTheme.parseHex(item['goalkeeper_body']?.toString())
          : defaultGoalkeeperBodyFor(slot);
      final goalkeeperTrim = item.containsKey('goalkeeper_trim')
          ? AppTheme.parseHex(item['goalkeeper_trim']?.toString())
          : defaultGoalkeeperTrimFor(slot);
      final label = item['label']?.toString().trim() ?? '';
      if (body == null ||
          trim == null ||
          goalkeeperBody == null ||
          goalkeeperTrim == null ||
          label.isEmpty) {
        return null;
      }
      bySlot[slot] = ClubKit(
        slot: slot,
        label: label,
        body: body,
        trim: trim,
        goalkeeperBody: goalkeeperBody,
        goalkeeperTrim: goalkeeperTrim,
        enabled: item['enabled'] != false,
      );
    }
    if (bySlot.length != JerseyOption.values.length) return null;
    return [for (final slot in JerseyOption.values) bySlot[slot]!];
  }
}
