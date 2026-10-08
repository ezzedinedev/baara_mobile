package com.stratetix.baara

import android.app.KeyguardManager
import android.content.Context
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    /**
     * Surveillance des quiz.
     *
     * FLAG_SECURE interdit au systeme de capturer la fenetre : plus de capture
     * d'ecran, plus d'enregistrement video, et l'apercu dans le multitache est
     * masque. C'est la seule facon fiable de bloquer la copie de l'epreuve sur
     * Android — cote applicatif, on ne peut que constater apres coup.
     *
     * Le drapeau est pose a l'entree du quiz et retire a la sortie : le laisser
     * en permanence casserait les captures legitimes du reste de l'app.
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "baara/quiz_proctoring"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableSecure" -> {
                    runOnUiThread {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(true)
                }
                "disableSecure" -> {
                    runOnUiThread {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(true)
                }
                // Android bloque la capture au lieu de la detecter : rien a
                // signaler a posteriori, contrairement a iOS.
                "isScreenshotDetectionSupported" -> result.success(false)
                else -> result.notImplemented()
            }
        }

        // Verrouillage de l'app : savoir si le téléphone a un code, un schéma
        // ou une empreinte. Sans cela, local_auth attend indéfiniment quand
        // l'appareil n'est pas protégé.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "baara/device_security"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isDeviceSecure" -> {
                    val keyguard = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
                    result.success(keyguard?.isDeviceSecure ?: false)
                }
                else -> result.notImplemented()
            }
        }
    }
}
