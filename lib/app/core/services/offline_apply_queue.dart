import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../constants/api_constants.dart';
import '../network/api_provider.dart';
import '../utils/offline_error.dart';
import '../widgets/common/app_toast.dart';
import 'local_cache_service.dart';

/// Une candidature soumise alors que l'appareil etait hors-ligne, en attente de
/// renvoi. On garde un instantane leger de l'offre pour l'afficher dans « Mes
/// candidatures » sans dependre d'un rechargement reseau.
class PendingApply {
  const PendingApply({
    required this.offerId,
    required this.offerTitle,
    required this.company,
    this.logoUrl,
    this.screeningAnswers,
    required this.queuedAt,
  });

  final String offerId;
  final String offerTitle;
  final String company;
  final String? logoUrl;
  final Map<String, dynamic>? screeningAnswers;
  final DateTime queuedAt;

  Map<String, dynamic> toJson() => {
        'offer_id': offerId,
        'offer_title': offerTitle,
        'company': company,
        if (logoUrl != null) 'logo_url': logoUrl,
        if (screeningAnswers != null) 'screening_answers': screeningAnswers,
        'queued_at': queuedAt.toIso8601String(),
      };

  static PendingApply? fromJson(Map<String, dynamic> json) {
    final id = json['offer_id']?.toString();
    if (id == null || id.isEmpty) return null;
    return PendingApply(
      offerId: id,
      offerTitle: json['offer_title']?.toString() ?? 'Offre',
      company: json['company']?.toString() ?? '',
      logoUrl: json['logo_url']?.toString(),
      screeningAnswers: json['screening_answers'] is Map<String, dynamic>
          ? json['screening_answers'] as Map<String, dynamic>
          : null,
      queuedAt:
          DateTime.tryParse(json['queued_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

/// File d'attente des candidatures hors-ligne. Persiste dans le cache local
/// (purge auto au logout), ecoute le retour du reseau et rejoue les envois.
///
/// Decouple du repository d'offres : poste directement `POST /applications`
/// via [ApiProvider] (permanent, dispo des l'InitialBinding).
class OfflineApplyQueue extends GetxService {
  OfflineApplyQueue(this._api);

  final ApiProvider _api;
  final LocalCacheService _cache = LocalCacheService.instance;

  /// Candidatures en attente d'envoi (observable pour l'UI).
  final pending = <PendingApply>[].obs;

  bool _isFlushing = false;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  @override
  void onInit() {
    super.onInit();
    _restore();
    // Renvoi opportuniste au demarrage + a chaque retour de connectivite.
    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) flush();
    });
  }

  @override
  void onClose() {
    _connSub?.cancel();
    super.onClose();
  }

  Future<void> _restore() async {
    final raw = await _cache.readList(CacheKeys.pendingApplies);
    if (raw == null) return;
    final items = raw
        .whereType<Map<String, dynamic>>()
        .map(PendingApply.fromJson)
        .whereType<PendingApply>()
        .toList();
    pending.assignAll(items);
    if (pending.isNotEmpty) flush();
  }

  Future<void> _persist() async {
    await _cache.writeJson(
      CacheKeys.pendingApplies,
      pending.map((e) => e.toJson()).toList(),
    );
  }

  bool contains(String offerId) => pending.any((e) => e.offerId == offerId);

  /// Ajoute une candidature a la file (dedoublonnee par offre) et persiste.
  Future<void> enqueue(PendingApply apply) async {
    if (contains(apply.offerId)) return;
    pending.add(apply);
    await _persist();
  }

  Future<void> remove(String offerId) async {
    pending.removeWhere((e) => e.offerId == offerId);
    await _persist();
  }

  /// Tente de renvoyer toutes les candidatures en attente. Best-effort :
  /// - succes serveur → retiree + toast ;
  /// - rejet serveur (deja postule, offre fermee, validation…) → retiree
  ///   silencieusement (inutile de retenter) ;
  /// - erreur reseau → conservee, on retentera au prochain retour de reseau.
  Future<void> flush() async {
    if (_isFlushing || pending.isEmpty) return;
    _isFlushing = true;
    try {
      // Copie : on mute `pending` pendant l'iteration.
      for (final apply in List<PendingApply>.of(pending)) {
        try {
          final response = await _api.postJson(
            ApiConstants.applications,
            {
              'offer_id': apply.offerId,
              if (apply.screeningAnswers != null)
                'screening_answers': apply.screeningAnswers,
            },
          );
          if (response['success'] == true) {
            await remove(apply.offerId);
            AppToast.success(
              'Candidature envoyee',
              '${apply.company.isEmpty ? '' : '${apply.company} · '}${apply.offerTitle}',
            );
          } else {
            // Le serveur a repondu (ex. 422 deja postule) : action resolue,
            // on ne boucle pas dessus.
            await remove(apply.offerId);
          }
        } catch (e) {
          if (isOfflineError(e)) {
            // Toujours hors-ligne : on garde et on arrete la (les suivantes
            // echoueront pareil). On retentera au prochain evenement reseau.
            break;
          }
          // Erreur non-reseau (bug, 500 persistant…) : on retire pour eviter
          // une file bloquee indefiniment.
          if (kDebugMode) debugPrint('[OfflineApplyQueue] drop ${apply.offerId}: $e');
          await remove(apply.offerId);
        }
      }
    } finally {
      _isFlushing = false;
    }
  }
}
