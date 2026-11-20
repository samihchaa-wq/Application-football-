import 'package:flutter_test/flutter_test.dart';
import 'package:petit_filet/core/push/home_screen_install.dart';

const _iPhoneSafari =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 18_1 like Mac OS X) AppleWebKit/605.1.15 '
    '(KHTML, like Gecko) Version/18.1 Mobile/15E148 Safari/604.1';
const _iPadDesktopMode =
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 '
    '(KHTML, like Gecko) Version/18.1 Safari/605.1.15';
const _android = 'Mozilla/5.0 (Linux; Android 15; Pixel 9) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36';

void main() {
  test('iPhone dans Safari : il faut installer l’appli', () {
    expect(
      needsHomeScreenInstall(
        userAgent: _iPhoneSafari,
        maxTouchPoints: 5,
        standalone: false,
      ),
      isTrue,
    );
  });

  test('iPhone déjà ouvert depuis l’écran d’accueil : rien à demander', () {
    expect(
      needsHomeScreenInstall(
        userAgent: _iPhoneSafari,
        maxTouchPoints: 5,
        standalone: true,
      ),
      isFalse,
    );
  });

  test('iPad récent qui se présente comme un Mac : reconnu', () {
    expect(
      needsHomeScreenInstall(
        userAgent: _iPadDesktopMode,
        maxTouchPoints: 5,
        standalone: false,
      ),
      isTrue,
    );
  });

  test('vrai Mac et Android : pas de conseil d’installation', () {
    expect(
      needsHomeScreenInstall(
        userAgent: _iPadDesktopMode,
        maxTouchPoints: 0,
        standalone: false,
      ),
      isFalse,
    );
    expect(
      needsHomeScreenInstall(
        userAgent: _android,
        maxTouchPoints: 5,
        standalone: false,
      ),
      isFalse,
    );
  });

  test('la famille du téléphone choisit les bons gestes', () {
    expect(
      installPlatformFor(userAgent: _iPhoneSafari, maxTouchPoints: 5),
      InstallPlatform.iphone,
    );
    expect(
      installPlatformFor(userAgent: _iPadDesktopMode, maxTouchPoints: 5),
      InstallPlatform.iphone,
    );
    expect(
      installPlatformFor(userAgent: _android, maxTouchPoints: 5),
      InstallPlatform.android,
    );
    expect(
      installPlatformFor(userAgent: _iPadDesktopMode, maxTouchPoints: 0),
      InstallPlatform.other,
    );
  });
}
