import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:as_grinta/core/club/club_kits.dart';
import 'package:as_grinta/core/widgets/kit_portrait.dart';
import 'package:as_grinta/core/widgets/portrait_alignment_guide.dart';
import 'package:as_grinta/core/storage/avatar_image.dart';
import 'package:as_grinta/core/storage/avatar_image_codec.dart'
    deferred as avatar_codec;
import 'package:flutter/material.dart';

/// Ouvre l'éditeur utilisé pour les photos de profil : déplacement libre,
/// pinch-to-zoom / dézoom et export JPEG, ou PNG si la photo a des zones
/// transparentes.
///
/// Un patron est posé sur l'aperçu (ovale du visage, épaules, couronne de
/// l'Étoile du match à sa place sur le terrain) pour cadrer tous les joueurs
/// de la même façon. Il n'est jamais enregistré dans l'image.
///
/// L'export est calculé directement depuis l'image source et la matrice de
/// transformation. On ne capture pas le widget à l'écran : cela évite les
/// échecs de RenderRepaintBoundary sur Flutter Web / iOS PWA et garantit un
/// rendu identique à l'aperçu.
Future<Uint8List?> cropProfilePhoto(
  BuildContext context,
  Uint8List bytes, {
  String title = 'Recadrer la photo',
  String instructions = 'Déplace et pince pour zoomer : le visage dans '
      'l’ovale, du haut du front au menton.',
  String confirmLabel = 'Utiliser cette photo',
  Color previewColor = const Color(0xFF174936),
  Color previewBorderColor = const Color(0xFF6DAD8B),
  ClubKit? kit,
  bool isGoalkeeper = false,
}) {
  return showDialog<Uint8List?>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PhotoCropDialog(
      bytes: bytes,
      title: title,
      instructions: instructions,
      confirmLabel: confirmLabel,
      previewColor: previewColor,
      previewBorderColor: previewBorderColor,
      kit: kit,
      isGoalkeeper: isGoalkeeper,
    ),
  );
}

class _PhotoCropDialog extends StatefulWidget {
  const _PhotoCropDialog({
    required this.bytes,
    required this.title,
    required this.instructions,
    required this.confirmLabel,
    required this.previewColor,
    required this.previewBorderColor,
    required this.kit,
    required this.isGoalkeeper,
  });

  final Uint8List bytes;
  final String title;
  final String instructions;
  final String confirmLabel;
  final Color previewColor;
  final Color previewBorderColor;
  final ClubKit? kit;
  final bool isGoalkeeper;

  @override
  State<_PhotoCropDialog> createState() => _PhotoCropDialogState();
}

class _PhotoCropDialogState extends State<_PhotoCropDialog> {
  static const double _cropSize = 300;

  /// Le rendu est calculé à la taille de stockage, pas à un multiple arbitraire
  /// de l'aperçu : c'est ce qui décide du poids réel de la photo à télécharger.
  static const double _exportScale = avatarStorageSide / _cropSize;

  final _transformationController = TransformationController();
  double _childWidth = _cropSize;
  double _childHeight = _cropSize;
  bool _ready = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    final codec = await ui.instantiateImageCodec(widget.bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final coverScale = math.max(
      _cropSize / image.width,
      _cropSize / image.height,
    );
    final childWidth = image.width * coverScale;
    final childHeight = image.height * coverScale;
    image.dispose();
    codec.dispose();
    if (!mounted) return;

    setState(() {
      _childWidth = childWidth;
      _childHeight = childHeight;
      _transformationController.value = Matrix4.identity()
        ..translateByDouble(
          -(childWidth - _cropSize) / 2,
          -(childHeight - _cropSize) / 2,
          0,
          1,
        );
      _ready = true;
    });
  }

  Future<Uint8List> _renderCrop() async {
    final codec = await ui.instantiateImageCodec(widget.bytes);
    final frame = await codec.getNextFrame();
    final source = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.scale(_exportScale, _exportScale);
    canvas.clipRect(ui.Rect.fromLTWH(0, 0, _cropSize, _cropSize));
    // Pas de fond peint : une photo détourée garde sa transparence, comme une
    // zone laissée découverte par le cadrage (voir encodeAvatar).
    canvas.transform(_transformationController.value.storage);
    canvas.drawImageRect(
      source,
      ui.Rect.fromLTWH(0, 0, source.width.toDouble(), source.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, _childWidth, _childHeight),
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );

    final picture = recorder.endRecording();
    const side = avatarStorageSide;
    final output = await picture.toImage(side, side);
    // dart:ui ne sait encoder que du PNG, sans perte : les avatars pesaient
    // 171 à 250 ko pièce, soit ~2,5 Mo pour une composition de onze joueurs.
    // On récupère donc les pixels bruts et on les encode en JPEG, sauf photo
    // transparente (voir encodeAvatar).
    final data = await output.toByteData(format: ui.ImageByteFormat.rawRgba);

    output.dispose();
    source.dispose();
    codec.dispose();

    if (data == null) {
      throw StateError('Impossible de générer la photo recadrée.');
    }

    // Encodeur chargé à la demande (voir avatar_image_codec.dart).
    await avatar_codec.loadLibrary();
    return avatar_codec.encodeAvatarFromRawRgba(data, side, side);
  }

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final jpeg = await _renderCrop();
      if (!mounted) return;
      Navigator.pop(context, jpeg);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de préparer cette image. Réessaie.'),
        ),
      );
    }
  }


  static const _background = Color(0xFF080F19);
  static const _panel = Color(0xFF111C2B);
  static const _outline = Color(0xFF3A4A5D);

  ClubKit get _previewKit => widget.kit ?? ClubKits.enabled.first;

  /// Une seule image source, déplacée sous des calques NON exportés.
  Widget _photoFrame({required bool interactive, required bool guide}) {
    final photo = !_ready
        ? const Center(child: CircularProgressIndicator())
        : interactive
            ? InteractiveViewer(
                transformationController: _transformationController,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(_cropSize * 4),
                minScale: 0.05,
                maxScale: 8,
                panEnabled: true,
                scaleEnabled: true,
                child: Image.memory(
                  widget.bytes,
                  width: _childWidth,
                  height: _childHeight,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
              )
            : AnimatedBuilder(
                animation: _transformationController,
                builder: (context, child) => Transform(
                  alignment: Alignment.topLeft,
                  transform: _transformationController.value,
                  child: child,
                ),
                child: Image.memory(
                  widget.bytes,
                  width: _childWidth,
                  height: _childHeight,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
              );

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const TransparentPhotoBackground(),
          photo,
          // Le maillot du club est purement visuel : l'export n'enregistre
          // que les pixels de la photo et la matrice de recadrage.
          IgnorePointer(
            child: KitPortrait(
              kit: _previewKit,
              isGoalkeeper: widget.isGoalkeeper,
              child: const SizedBox.expand(),
            ),
          ),
          if (guide) const PortraitAlignmentGuide(),
        ],
      ),
    );
  }

  Widget _mainPreview() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _outline, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: _photoFrame(interactive: true, guide: true),
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Déplace la photo ou pince pour zoomer. Les guides ne seront pas enregistrés.',
            style: TextStyle(color: Color(0xFFAAB7C7), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      );

  Widget _infoCard({
    required IconData icon,
    required String title,
    required Widget child,
    Color iconColor = const Color(0xFF37A7FF),
  }) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _panel,
          border: Border.all(color: _outline),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 22),
                const SizedBox(width: 9),
                Text(title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );

  Widget _example(String label, bool correct, Alignment alignment) =>
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: correct
                ? const Color(0xFF115A28)
                : const Color(0xFF622425),
            border: Border.all(
                color: correct
                    ? const Color(0xFF55DE58)
                    : const Color(0xFFFF6262),
                width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(9)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const TransparentPhotoBackground(),
                      Image.memory(widget.bytes,
                          fit: BoxFit.cover, alignment: alignment),
                      IgnorePointer(
                        child: KitPortrait(
                          kit: _previewKit,
                          isGoalkeeper: widget.isGoalkeeper,
                          child: const SizedBox.expand(),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: Icon(
                          correct ? Icons.check_circle : Icons.cancel,
                          color: correct
                              ? const Color(0xFF59E566)
                              : const Color(0xFFFF4444),
                          size: 25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    )),
              ),
            ],
          ),
        ),
      );

  Widget _sidebar() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _infoCard(
            icon: Icons.info_outline_rounded,
            title: 'Patron de cadrage',
            child: const Text(
              'Positionne ta photo pour que la tête soit bien centrée et à la bonne taille. Le maillot du club s’appliquera automatiquement.',
              style: TextStyle(color: Colors.white, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          _infoCard(
            icon: Icons.check_circle,
            title: 'Conseils',
            iconColor: Color(0xFF5DDA4C),
            child: const Text(
              '• Visage de face, bien centré\n'
              '• Regard droit (de préférence)\n'
              '• Tête entière visible (sans coupe)\n'
              '• Éclairage clair et uniforme\n'
              '• Fond simple (ou transparent)',
              style: TextStyle(color: Colors.white, height: 1.45),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _example('Correct', true, Alignment.center),
              const SizedBox(width: 7),
              _example('Trop haut', false, Alignment.topCenter),
              const SizedBox(width: 7),
              _example('Décalé', false, Alignment.centerRight),
            ],
          ),
        ],
      );

  Widget _finalPreview() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Aperçu final',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 156,
              height: 156,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: SizedBox(
                    width: _cropSize,
                    height: _cropSize,
                    child: _photoFrame(interactive: false, guide: false),
                  ),
                ),
              ),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(screen.width - 32, 940.0);
    final isCompact = dialogWidth < 680;
    return Dialog(
      backgroundColor: _background,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: _outline),
      ),
      child: SizedBox(
        width: dialogWidth,
        height: math.min(screen.height - 32, 750.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
              child: Row(
                children: [
                  const Icon(Icons.checkroom_outlined,
                      size: 27, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title == 'Recadrer la photo'
                          ? 'Ajouter la photo du joueur'
                          : widget.title,
                      maxLines: 2,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isCompact ? 18 : 23,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed:
                        _busy ? null : () => Navigator.pop(context, null),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            const Divider(color: _outline, height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: isCompact
                    ? Column(
                        children: [
                          _mainPreview(),
                          const SizedBox(height: 14),
                          _sidebar(),
                          const SizedBox(height: 16),
                          _finalPreview(),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 11, child: _mainPreview()),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 10,
                            child: Column(
                              children: [
                                _sidebar(),
                                const SizedBox(height: 14),
                                _finalPreview(),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const Divider(color: _outline, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _busy ? null : () => Navigator.pop(context, null),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: _outline)),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: !_ready || _busy ? null : _confirm,
                      icon: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.check_circle_outline),
                      label: Text(widget.confirmLabel),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE3B45E),
                        foregroundColor: const Color(0xFF101723),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
