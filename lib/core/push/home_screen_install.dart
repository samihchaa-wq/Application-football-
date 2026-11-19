/// Règle pure : faut-il demander d'ajouter l'application à l'écran d'accueil
/// pour recevoir les notifications ?
///
/// Sur iPhone et iPad, Safari ne délivre les notifications Web qu'aux
/// applications ajoutées à l'écran d'accueil (iOS 16.4 et plus). Ouverte
/// dans un onglet, l'application ne peut pas s'abonner, et rien ne le disait
/// au joueur : il ne recevait rien sans savoir pourquoi.
///
/// [userAgent] : `navigator.userAgent`. [maxTouchPoints] : distingue un iPad
/// récent, qui se présente comme un Mac. [standalone] : vrai quand
/// l'application tourne déjà depuis l'écran d'accueil.
bool needsHomeScreenInstall({
  required String userAgent,
  required int maxTouchPoints,
  required bool standalone,
}) {
  if (standalone) return false;
  final ua = userAgent.toLowerCase();
  final iPhoneOrIPod = ua.contains('iphone') || ua.contains('ipod');
  final classicIPad = ua.contains('ipad');
  final desktopModeIPad = ua.contains('macintosh') && maxTouchPoints > 1;
  return iPhoneOrIPod || classicIPad || desktopModeIPad;
}
