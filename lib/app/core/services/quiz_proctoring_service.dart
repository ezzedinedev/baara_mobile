import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Pont vers la protection native pendant un quiz.
///
/// Les deux plateformes ne peuvent pas la même chose, et il vaut mieux le dire
/// que le maquiller :
/// - **Android** : `FLAG_SECURE` interdit au système de capturer la fenêtre —
///   captures d'écran, enregistrement vidéo et aperçu multitâche sont bloqués.
/// - **iOS** : Apple interdit de bloquer la capture. On la **détecte** donc
///   (`userDidTakeScreenshotNotification`) et on la remonte au serveur comme
///   incident.
///
/// Dans les deux cas, c'est le backend qui décide de la sanction : ces mesures
/// ne sont qu'un signalement, jamais un verdict.
class QuizProctoringService {
  QuizProctoringService._();

  static final QuizProctoringService instance = QuizProctoringService._();

  static const MethodChannel _channel = MethodChannel('baara/quiz_proctoring');

  VoidCallback? _onScreenshot;
  bool _listening = false;

  /// Active la protection et branche la détection de capture.
  /// [onScreenshot] n'est appelé que sur les plateformes qui savent détecter.
  Future<void> start({required VoidCallback onScreenshot}) async {
    _onScreenshot = onScreenshot;

    if (!_listening) {
      _channel.setMethodCallHandler(_handleNativeCall);
      _listening = true;
    }

    await _invoke('enableSecure');
  }

  /// Rend l'appareil à son état normal : sans ça, l'utilisateur ne pourrait
  /// plus faire la moindre capture dans le reste de l'app.
  Future<void> stop() async {
    _onScreenshot = null;
    await _invoke('disableSecure');
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onScreenshot') {
      _onScreenshot?.call();
    }
  }

  Future<void> _invoke(String method) async {
    try {
      await _channel.invokeMethod<bool>(method);
    } on MissingPluginException {
      // Plateforme sans implémentation native (desktop, tests) : la surveillance
      // applicative (arrière-plan, multitâche) reste active.
    } on PlatformException catch (e) {
      debugPrint('Surveillance quiz indisponible ($method) : ${e.message}');
    }
  }
}
