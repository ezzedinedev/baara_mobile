import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var proctoringChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Surveillance des quiz.
    //
    // iOS n'autorise pas a bloquer la capture d'ecran : contrairement a Android
    // (FLAG_SECURE), on ne peut que la DETECTER apres coup. On remonte donc
    // l'evenement a Dart, qui le journalise comme incident cote serveur — le
    // seuil d'alerte et l'invalidation restent decides par le backend.
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "jobaway/quiz_proctoring",
        binaryMessenger: controller.binaryMessenger
      )
      proctoringChannel = channel

      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "enableSecure", "disableSecure":
          // Aucun equivalent de FLAG_SECURE sur iOS : la detection prend le relais.
          result(false)
        case "isScreenshotDetectionSupported":
          result(true)
        default:
          result(FlutterMethodNotImplemented)
        }
      }

      NotificationCenter.default.addObserver(
        self,
        selector: #selector(userDidTakeScreenshot),
        name: UIApplication.userDidTakeScreenshotNotification,
        object: nil
      )
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  @objc private func userDidTakeScreenshot() {
    proctoringChannel?.invokeMethod("onScreenshot", arguments: nil)
  }
}
