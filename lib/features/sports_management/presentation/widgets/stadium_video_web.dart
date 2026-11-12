import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:as_grinta/core/theme/app_theme.dart';
import 'package:as_grinta/features/sports_management/presentation/widgets/stadium_club_colors_web.dart';
import 'package:as_grinta/features/sports_management/presentation/widgets/stadium_poster.dart';
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// La vidéo muette du stade, posée sur son image fixe.
///
/// Tout est fait pour qu'un téléphone ne puisse pas la refuser :
/// - elle est téléchargée d'un bloc puis lue depuis la mémoire du téléphone :
///   aucun téléchargement par morceaux, que l'ancien service worker faisait
///   échouer, et elle reste ensuite dans le cache pour la fois suivante ;
/// - un téléphone qui ne lit pas la grande version sans à-coups reçoit la
///   version légère ;
/// - elle est muette, lue dans la page, et « débloquée » pendant l'appui sur
///   le bouton qui l'ouvre ([primeStadiumVideo]) : même en économie
///   d'énergie, l'iPhone accepte alors de la lire ;
/// - arrivée en retard, elle rejoint la présentation au bon instant.
///
/// Tant qu'elle ne joue pas, c'est l'image fixe du stade qu'on voit, jamais un
/// rectangle noir. [StadiumVideo.onStatus] dit ce qui s'est passé.
///
/// Le stade est repeint aux couleurs du club ([StadiumRecolor]) : la vidéo
/// d'origine reste la source, mais c'est sa copie repeinte qu'on voit. Sans
/// repeinte possible, la vidéo et l'image fixe sont montrées atténuées, sans
/// les couleurs d'un autre club.
class StadiumVideo extends StatefulWidget {
  const StadiumVideo({
    super.key,
    required this.video,
    required this.lightVideo,
    required this.poster,
    required this.playing,
    required this.take,
    required this.elapsed,
    required this.onReady,
    this.onStatus,
  });

  /// Chemins des fichiers dans les assets de l'appli.
  final String video;
  final String lightVideo;
  final String poster;

  /// La présentation tourne : la vidéo doit jouer.
  final bool playing;

  /// Change à chaque « Revoir » : la vidéo repart du début.
  final int take;

  /// Instant de la présentation, en secondes.
  final double Function() elapsed;

  /// Appelé une fois, dès que la vidéo peut démarrer ou qu'on y renonce.
  final VoidCallback onReady;

  /// État de la vidéo en clair, pour l'aperçu de l'admin.
  final ValueChanged<String>? onStatus;

  @override
  State<StadiumVideo> createState() => _StadiumVideoState();
}

web.HTMLVideoElement? _primed;

/// À appeler pendant l'appui sur le bouton qui ouvre la vidéo, avant toute
/// attente : une lecture lancée par un geste « débloque » la balise vidéo,
/// que le téléphone laissera ensuite jouer sans nouveau geste.
void primeStadiumVideo() {
  if (_primed != null) return;
  final video = _newVideoElement();
  unawaited(
    video.play().toDart.then<void>((_) {}, onError: (Object _) {}),
  );
  video.pause();
  _primed = video;
}

web.HTMLVideoElement _newVideoElement() {
  final video = web.HTMLVideoElement()
    ..muted = true
    ..defaultMuted = true
    ..playsInline = true
    ..autoplay = false
    ..controls = false
    ..preload = 'auto';
  // Les attributs comptent autant que les propriétés pour Safari.
  video
    ..setAttribute('muted', '')
    ..setAttribute('playsinline', '')
    ..setAttribute('webkit-playsinline', '')
    ..setAttribute('disablepictureinpicture', '')
    ..setAttribute('disableremoteplayback', '');
  video.style
    ..width = '100%'
    ..height = '100%'
    ..objectFit = 'cover'
    ..pointerEvents = 'none'
    ..backgroundColor = 'transparent'
    // Atténuée : on ne la voit qu'en secours, sous la toile repeinte.
    ..filter = 'saturate($kNeutralStadiumSaturation)';
  return video;
}

class _StadiumVideoState extends State<StadiumVideo> {
  static int _views = 0;

  final String _viewType = 'as-grinta-stade-${_views++}';
  late final web.HTMLVideoElement _video;
  late final web.HTMLDivElement _frame;
  StadiumRecolor? _recolor;
  final web.HTMLImageElement _posterImage = web.HTMLImageElement();
  bool _posterDrawn = false;
  double _drawnAt = -1;
  int? _animationFrame;
  final _subscriptions = <StreamSubscription<web.Event>>[];
  final Stopwatch _clock = Stopwatch()..start();
  Timer? _giveUp;
  bool _reported = false;
  bool _attached = false;
  bool _sourceSet = false;
  bool _played = false;
  String? _objectUrl;
  String _version = '';
  String? _problem;
  final List<String> _events = [];

  @override
  void initState() {
    super.initState();
    _video = _primed ?? _newVideoElement();
    final unlocked = _primed != null;
    _primed = null;
    // Pas d'image fixe dans la balise : elle montrerait les couleurs
    // d'origine. L'image fixe atténuée est dessous, côté Flutter, et sa copie
    // repeinte est dessinée sur la toile dès qu'elle est chargée.
    _video.removeAttribute('poster');
    _frame = web.HTMLDivElement();
    _frame.style
      ..position = 'relative'
      ..width = '100%'
      ..height = '100%'
      ..pointerEvents = 'none';
    _frame.append(_video);
    _recolor = StadiumRecolor.create(
      primary: AppTheme.primary,
      secondary: AppTheme.accent,
    );
    final recolor = _recolor;
    if (recolor != null) {
      _frame.append(recolor.canvas);
      _posterImage.src = ui_web.assetManager.getAssetUrl(widget.poster);
      _animationFrame = web.window.requestAnimationFrame(_paint.toJS);
      _log('repeinte aux couleurs du club');
    } else {
      _log('repeinte impossible, vidéo atténuée');
    }
    _subscriptions
      ..add(_video.onCanPlay.listen((_) {
        // Arrivée en retard : elle se recale sur la présentation.
        if (widget.playing && !_played) _tryPlay();
        _report();
      }))
      ..add(_video.onPlaying.listen((_) {
        if (!widget.playing) {
          // Lecture d'essai avant le départ : retour au début.
          _video.pause();
          _video.currentTime = 0;
        } else {
          _played = true;
          _status();
        }
        _report();
      }))
      ..add(_video.onError.listen((_) {
        final code = _video.error?.code;
        _problem = 'vidéo illisible sur ce téléphone (erreur $code)';
        _status();
        _report();
      }));
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int _) => _frame,
    );
    _log(unlocked ? 'débloquée par l’appui' : 'sans appui préalable');
    unawaited(_loadSource());
    _giveUp = Timer(const Duration(seconds: 6), () {
      _problem ??= 'vidéo trop longue à charger';
      _status();
      _report();
    });
  }

  /// Redessine la toile à chaque nouvelle image de la vidéo, ou l'image fixe
  /// tant que la vidéo n'a rien montré.
  void _paint(double _) {
    final recolor = _recolor;
    if (!mounted || recolor == null) return;
    final videoShown = _video.readyState >= 2 &&
        _video.videoWidth > 0 &&
        (_played || _video.currentTime > 0);
    var ok = true;
    if (videoShown) {
      if (_video.currentTime != _drawnAt) {
        _drawnAt = _video.currentTime;
        ok = recolor.draw(_video, _video.videoWidth, _video.videoHeight);
      }
    } else if (!_posterDrawn &&
        _posterImage.complete &&
        _posterImage.naturalWidth > 0) {
      ok = _posterDrawn = recolor.draw(
        _posterImage,
        _posterImage.naturalWidth,
        _posterImage.naturalHeight,
      );
    }
    if (!ok) {
      // La toile a échoué en route : on la retire, la vidéo atténuée reste.
      recolor.canvas.remove();
      _recolor = null;
      _log('repeinte interrompue, vidéo atténuée');
      return;
    }
    _animationFrame = web.window.requestAnimationFrame(_paint.toJS);
  }

  void _log(String event) {
    _events.add('${(_clock.elapsedMilliseconds / 1000).toStringAsFixed(1)} s '
        '$event');
  }

  /// La grande version si le téléphone la lit sans à-coups, la légère sinon.
  Future<String> _pickVersion() async {
    try {
      final capabilities = web.window.navigator.mediaCapabilities;
      final info = await capabilities
          .decodingInfo(
            web.MediaDecodingConfiguration(
              type: 'file',
              video: web.VideoConfiguration(
                contentType: 'video/mp4; codecs="avc1.640032"',
                width: 1080,
                height: 2338,
                bitrate: 2300000,
                framerate: 30,
              ),
            ),
          )
          .toDart
          .timeout(const Duration(milliseconds: 800));
      if (info.supported && info.smooth) {
        _version = '1080 px';
        return widget.video;
      }
    } catch (_) {
      // Navigateur ancien : on ne prend pas de risque.
    }
    _version = '720 px';
    return widget.lightVideo;
  }

  Future<void> _loadSource() async {
    final asset = await _pickVersion();
    final url = ui_web.assetManager.getAssetUrl(asset);
    _log('version $_version');
    String source = url;
    try {
      final response = await web.window.fetch(url.toJS).toDart.timeout(
            const Duration(seconds: 20),
          );
      if (!response.ok) throw StateError('HTTP ${response.status}');
      final blob = await response.blob().toDart;
      _objectUrl = web.URL.createObjectURL(blob);
      source = _objectUrl!;
      _log('téléchargée');
    } catch (error) {
      // Dernier recours : lecture directe depuis le réseau.
      _log('téléchargement en bloc impossible ($error)');
    }
    if (!mounted) return;
    _video.src = source;
    _sourceSet = true;
    _video.load();
    _tryPlay();
  }

  void _onAttached(int _) {
    _attached = true;
    _log('affichée');
    _tryPlay();
  }

  /// Lance (ou relance) la lecture au bon instant de la présentation.
  void _tryPlay() {
    if (!_sourceSet || !_attached || !mounted) return;
    if (widget.playing) {
      final target = widget.elapsed();
      if ((_video.currentTime - target).abs() > 0.35) {
        _video.currentTime = target;
      }
    }
    unawaited(
      _video.play().toDart.then<void>((_) {}, onError: (Object error) {
        String name;
        try {
          name = (error as web.DOMException).name;
        } catch (_) {
          name = '$error';
        }
        if (name == 'AbortError') return;
        final problem = 'lecture refusée par le téléphone ($name)';
        if (_problem != problem) {
          _problem = problem;
          _log(problem);
          _status();
        }
        _report();
      }),
    );
  }

  void _report() {
    if (_reported || !mounted) return;
    _reported = true;
    _giveUp?.cancel();
    widget.onReady();
  }

  void _status() {
    final summary = _played
        ? 'Vidéo du stade : animée ($_version).'
        : 'Vidéo du stade : image fixe — ${_problem ?? 'pas encore lancée'}.';
    widget.onStatus?.call('$summary\n${_events.join(' · ')}');
  }

  @override
  void didUpdateWidget(StadiumVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.take != oldWidget.take ||
        (widget.playing && !oldWidget.playing)) {
      _video.currentTime = 0;
      _tryPlay();
    }
  }

  @override
  void dispose() {
    _giveUp?.cancel();
    final animationFrame = _animationFrame;
    if (animationFrame != null) {
      web.window.cancelAnimationFrame(animationFrame);
    }
    _recolor = null;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _video
      ..pause()
      ..removeAttribute('src');
    _video.load();
    final objectUrl = _objectUrl;
    if (objectUrl != null) web.URL.revokeObjectURL(objectUrl);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        NeutralStadiumPoster(asset: widget.poster),
        HtmlElementView(
          viewType: _viewType,
          onPlatformViewCreated: _onAttached,
        ),
      ],
    );
  }
}
