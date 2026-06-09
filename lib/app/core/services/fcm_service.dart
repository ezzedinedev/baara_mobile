import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../features/home/presentation/controllers/home_controller.dart';
import '../constants/api_constants.dart';
import '../network/api_provider.dart';
import 'auth_token_store.dart';

/// Handler pour les messages recus quand l'app est en background ou
/// terminated. Doit etre une top-level function (pas une closure) pour
/// que Flutter puisse l'instancier dans un isolate dedie. Pas d'acces
/// au reste du runtime app — on se contente de logger.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // Pas de Firebase.initializeApp() ici : firebase_messaging le gere.
  // On laisse Android afficher le banner systeme (le payload backend doit
  // contenir une `notification` clef pour ca, pas seulement `data`).
  if (kDebugMode) {
    debugPrint('[FCM background] ${message.messageId} ${message.data}');
  }
}

/// Service singleton qui :
/// - demande la permission notif au boot (silencieux si deja accordee)
/// - recupere le token FCM, le pousse au backend (`PUT /notifications/fcm-token`)
/// - se reabonne au refresh du token (Firebase peut le rotater)
/// - affiche un local notification banner quand un push arrive en
///   foreground (FCM ne le fait pas tout seul — sinon l'utilisateur ne
///   voit rien si l'app est ouverte)
/// - route le tap-sur-notif vers l'ecran approprie via deeplink data
///   (notifiable_type / notifiable_id transmis dans `message.data`)
class FcmService extends GetxService {
  FcmService({ApiProvider? apiProvider, AuthTokenStore? tokenStore})
      : _apiProvider = apiProvider ?? Get.find<ApiProvider>(),
        _tokenStore = tokenStore ?? const AuthTokenStore();

  final ApiProvider _apiProvider;
  final AuthTokenStore _tokenStore;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;

  static const String _androidChannelId = 'opportune_default';
  static const String _androidChannelName = 'Notifications OpporTune';
  static const String _androidChannelDescription =
      'Messages, candidatures, formations.';

  /// Init passive : channels, listeners, handlers. **Ne demande pas la
  /// permission notif** et n'enregistre pas le token — c'est le job de
  /// `activateAfterLogin()`. Appele depuis main.dart au boot de l'app.
  ///
  /// Pourquoi ce split : demander la permission au boot avant meme que
  /// l'utilisateur ait vu l'ecran de connexion = mauvaise UX. Le user
  /// n'a aucun contexte → il refuse souvent → permission perdue ensuite
  /// (Android exige une procedure manuelle pour reactiver).
  Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    await _setupLocalNotifications();

    // Listeners de messages : actifs des le boot pour ne perdre aucun
    // payload, meme si la permission n'est pas encore accordee (le push
    // ne s'affichera pas mais le data peut quand meme etre traite).
    _foregroundSub?.cancel();
    _foregroundSub = FirebaseMessaging.onMessage.listen(_handleForeground);

    _openedAppSub?.cancel();
    _openedAppSub =
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = messaging.onTokenRefresh.listen(_pushTokenToBackend);

    // App ouverte depuis terminated par tap sur notif → routage deeplink.
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _handleNotificationTap(initial);
    }
  }

  /// Active FCM apres un login reussi : demande la permission systeme
  /// (Android 13+ / iOS) puis pousse le token au backend.
  ///
  /// Idempotent : si l'utilisateur a deja accorde la permission, l'API
  /// Firebase no-op et retourne directement le statut. Si refusee, on
  /// log et on s'arrete sans crash — le polling cloche continue.
  Future<void> activateAfterLogin() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      if (kDebugMode) debugPrint('[FCM] permission refusee par l user');
      return;
    }
    await _registerToken(messaging);
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // FCM s'en occupe deja
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotif.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        // Tap sur le banner local en foreground → on parse le payload
        // qu'on a injecte (memes clefs que les data Firebase pour rester
        // compat avec le routage des notifs background).
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        _routeFromPayload(_parsePayload(payload));
      },
    );

    // Android : creer le channel par defaut. Sans ca les notifs sont
    // affichees mais l'utilisateur ne peut pas regler son comportement.
    const channel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDescription,
      importance: Importance.high,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _registerToken(FirebaseMessaging messaging) async {
    try {
      final token = await messaging.getToken();
      if (token == null) return;
      await _pushTokenToBackend(token);
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] register token failed: $e');
    }
  }

  /// Force la resynchro du token au backend. A appeler depuis le flux de
  /// login juste apres `saveSession()` — sinon le token enregistre au boot
  /// (avant login) n'arrive jamais cote serveur (readToken() throw).
  Future<void> syncTokenToBackend() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _pushTokenToBackend(token);
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] sync token failed: $e');
    }
  }

  Future<void> _pushTokenToBackend(String token) async {
    final auth = await _tokenStore.readTokenOrNull();
    if (auth == null || auth.isEmpty) {
      // Normal au boot avant login — sync via activateAfterLogin().
      return;
    }
    try {
      await _apiProvider.putJson(
        ApiConstants.notificationsFcmToken,
        {
          // Backend (NotificationApiController@updateFcmToken) ne valide que
          // `fcm_token` ; ne pas envoyer de champ superflu.
          'fcm_token': token,
        },
        headers: ApiConstants.authHeaders(auth),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FCM] push token to backend failed: $e');
      }
    }
  }

  void _handleForeground(RemoteMessage message) {
    final data = message.data;
    final shortType = _shortenType(data['notifiable_type']?.toString());
    final targetId = data['notifiable_id']?.toString();
    var suppressBanner = false;
    if (shortType == 'conversation' &&
        targetId != null &&
        targetId.isNotEmpty &&
        Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      // Inbox : reload pour MAJ unreadCounters + lastMessage des cards.
      home.loadConversations();
      if (home.activeConversationId.value == targetId) {
        home.loadConversationThread(targetId);
        suppressBanner = true;
      }
    }

    if (suppressBanner) return;
    final notif = message.notification;
    if (notif == null) return;
    final payload = _serializePayload(data);
    _localNotif.show(
      id: message.hashCode,
      title: notif.title,
      body: notif.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          channelDescription: _androidChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }
  String? _shortenType(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final tail = raw.split('\\').last.toLowerCase();
    return tail == 'user' ? null : tail;
  }

  void _handleNotificationTap(RemoteMessage message) {
    _routeFromPayload(message.data);
  }
  void _routeFromPayload(Map<String, dynamic> data) {
    final id = data['notifiable_id']?.toString();
    if (id == null || id.isEmpty) return;
    final shortType = _shortenType(data['notifiable_type']?.toString());
    switch (shortType) {
      case 'conversation':
        Get.toNamed(AppRoutes.home);
        break;
      case 'application':
        Get.toNamed(AppRoutes.myApplications);
        break;
      case 'joboffer':
        Get.toNamed(AppRoutes.offerDetail.replaceFirst(':id', id));
        break;
      case 'trainingoffer':
      case 'training':
        Get.toNamed(AppRoutes.trainingDetail.replaceFirst(':id', id));
        break;
    }
  }

  String _serializePayload(Map<String, dynamic> data) {
    if (data.isEmpty) return '';
    return data.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
  }

  Map<String, dynamic> _parsePayload(String raw) {
    final map = <String, dynamic>{};
    for (final pair in raw.split('&')) {
      final i = pair.indexOf('=');
      if (i < 0) continue;
      map[pair.substring(0, i)] = Uri.decodeComponent(pair.substring(i + 1));
    }
    return map;
  }

  @override
  void onClose() {
    _tokenRefreshSub?.cancel();
    _foregroundSub?.cancel();
    _openedAppSub?.cancel();
    super.onClose();
  }
}
