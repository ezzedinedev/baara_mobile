import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
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

  /// Initialise FCM : permissions, channels, handlers, push token au backend.
  /// Appele depuis main.dart apres `Firebase.initializeApp()`.
  Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    // iOS : demander la permission. Android : auto-accordee jusqu'a 13 ;
    // depuis 13+ il faut demander aussi (Firebase le gere via cette API).
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      // L'utilisateur a refuse — on n'insiste pas. Le badge cloche dans
      // l'app continue de fonctionner (polling), juste pas de push systeme.
      return;
    }

    await _setupLocalNotifications();
    await _registerToken(messaging);

    // Le token peut tourner (reinstall, restore, etc.) — on resync.
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = messaging.onTokenRefresh.listen(_pushTokenToBackend);

    // Foreground : on affiche soi-meme un banner via flutter_local_notifs.
    _foregroundSub?.cancel();
    _foregroundSub = FirebaseMessaging.onMessage.listen(_handleForeground);

    // Tap sur banner alors que l'app etait en background → routage deeplink.
    _openedAppSub?.cancel();
    _openedAppSub =
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // App ouverte depuis terminated par tap sur notif : on traite le
    // initialMessage (sinon le deeplink est perdu).
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _handleNotificationTap(initial);
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // FCM s'en occupe deja
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotif.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
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

  Future<void> _pushTokenToBackend(String token) async {
    try {
      final auth = await _tokenStore.readToken();
      await _apiProvider.putJson(
        ApiConstants.notificationsFcmToken,
        {
          'fcm_token': token,
          'platform': defaultTargetPlatform == TargetPlatform.iOS
              ? 'ios'
              : 'android',
        },
        headers: ApiConstants.authHeaders(auth),
      );
    } catch (e) {
      // Echec silencieux : si on est offline ou non-authentifie, on
      // re-tentera au prochain refresh / login. Pas de notification au
      // user pour cette plomberie.
      if (kDebugMode) debugPrint('[FCM] push token to backend failed: $e');
    }
  }

  void _handleForeground(RemoteMessage message) {
    final notif = message.notification;
    if (notif == null) return;
    final payload = _serializePayload(message.data);
    _localNotif.show(
      message.hashCode,
      notif.title,
      notif.body,
      const NotificationDetails(
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

  void _handleNotificationTap(RemoteMessage message) {
    _routeFromPayload(message.data);
  }

  /// Routage commun : memes regles que `_navigateToTarget` cote
  /// notifications_screen — duplique ici parce que ce code peut s'executer
  /// avant que l'ecran des notifs n'ait ete monte. Garde la logique
  /// minimale : on ouvre la route, l'ecran cible recharge ce qu'il faut.
  void _routeFromPayload(Map<String, dynamic> data) {
    final type = (data['notifiable_type']?.toString() ?? '').toLowerCase();
    final id = data['notifiable_id']?.toString();
    if (id == null || id.isEmpty) return;
    // Backend envoie le FQN PHP. On normalise sur le tail.
    final shortType = type.split('\\').isEmpty
        ? type
        : type.split('\\').last;
    switch (shortType) {
      case 'conversation':
        // Pas d'overlay messaging direct ici : on bascule sur l'app et
        // le HomeController prendra l'id depuis un canal de comm dedie.
        // Pour l'instant on ouvre juste la liste messagerie.
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
