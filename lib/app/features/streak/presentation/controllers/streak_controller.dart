import 'dart:math' as math;

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pilote la « série quotidienne » (daily streak) — la gamification de
/// rétention inspirée d'Edomatch, mais branchée sur le design system maison.
///
/// L'état est **persisté localement** ([SharedPreferences]) et **idempotent** :
/// [checkIn] est appelé à chaque [onInit] et ne fait rien si l'utilisateur a
/// déjà été enregistré aujourd'hui. La logique :
/// - même jour que le dernier passage → no-op (on a déjà compté aujourd'hui) ;
/// - hier → la série continue ([currentStreak]++) ;
/// - plus ancien ou jamais → la série repart à 1 (reset).
///
/// On stocke aussi l'ensemble des dates ISO (`yyyy-MM-dd`) cochées, élagué à la
/// semaine courante, pour alimenter [weekDays] (calendrier hebdo Lun→Dim).
///
/// Même style persisté/hydraté que [SettingsController] : lecture du cache à
/// l'init, écriture immédiate à chaque mutation.
class StreakController extends GetxController {
  // ── Clés de persistance ────────────────────────────────────────────────────
  static const _kCurrentStreak = 'streak_current';
  static const _kBestStreak = 'streak_best';
  static const _kLastCheckIn = 'streak_last_checkin'; // ISO yyyy-MM-dd
  static const _kCheckedDays = 'streak_checked_days'; // liste ISO yyyy-MM-dd

  // ── État réactif ────────────────────────────────────────────────────────────
  /// Série en cours (nombre de jours consécutifs jusqu'à aujourd'hui).
  final currentStreak = 0.obs;

  /// Meilleure série jamais atteinte (record personnel).
  final bestStreak = 0.obs;

  /// Date du dernier passage enregistré (null si jamais venu).
  final lastCheckIn = Rxn<DateTime>();

  /// Ensemble des dates cochées (ISO `yyyy-MM-dd`) de la semaine courante.
  /// Privé : exposé via [weekDays] sous forme de 7 booléens.
  final _checkedDays = <String>{}.obs;

  /// 7 booléens (Lundi → Dimanche de la semaine COURANTE) : `true` si
  /// l'utilisateur s'est connecté ce jour-là. Dérivé de [_checkedDays].
  List<bool> get weekDays {
    final monday = _mondayOfCurrentWeek();
    return List<bool>.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      return _checkedDays.contains(_isoDate(day));
    });
  }

  /// 7 [DateTime] (Lundi → Dimanche) de la semaine courante — sert à afficher le
  /// numéro du jour sous chaque pastille du calendrier.
  List<DateTime> get weekDates {
    final monday = _mondayOfCurrentWeek();
    return List<DateTime>.generate(7, (i) => monday.add(Duration(days: i)));
  }

  /// `true` si l'utilisateur a déjà coché aujourd'hui (pour le bandeau « C'est
  /// fait pour aujourd'hui »).
  bool get checkedInToday {
    final last = lastCheckIn.value;
    return last != null && _isSameDay(last, DateTime.now());
  }

  @override
  void onInit() {
    super.onInit();
    // 1) Hydrate depuis le cache (affichage instantané, hors-ligne).
    //    2) puis enregistre le passage du jour (idempotent).
    _hydrateThenCheckIn();
  }

  Future<void> _hydrateThenCheckIn() async {
    await _hydrateFromCache();
    await checkIn();
  }

  /// Recharge l'état depuis [SharedPreferences].
  Future<void> _hydrateFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    currentStreak.value = prefs.getInt(_kCurrentStreak) ?? 0;
    bestStreak.value = prefs.getInt(_kBestStreak) ?? 0;

    final lastIso = prefs.getString(_kLastCheckIn);
    lastCheckIn.value = lastIso == null ? null : DateTime.tryParse(lastIso);

    final stored = prefs.getStringList(_kCheckedDays) ?? const <String>[];
    _checkedDays
      ..clear()
      ..addAll(stored);
    _pruneToCurrentWeek();
  }

  /// Enregistre le passage d'aujourd'hui. **Idempotent** : aucun effet si déjà
  /// compté aujourd'hui. Met à jour la série, le record, et persiste le tout.
  Future<void> checkIn() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = lastCheckIn.value;

    if (last != null && _isSameDay(last, today)) {
      // Déjà passé aujourd'hui → on s'assure juste que la pastille du jour est
      // bien cochée (cas d'un cache partiel) puis on sort.
      if (_checkedDays.add(_isoDate(today))) {
        _pruneToCurrentWeek();
        await _persistCheckedDays();
      }
      return;
    }

    if (last != null &&
        _isSameDay(last, today.subtract(const Duration(days: 1)))) {
      // Dernier passage = hier → la série continue.
      currentStreak.value = currentStreak.value + 1;
    } else {
      // Plus ancien (trou) ou tout premier passage → la série repart à 1.
      currentStreak.value = 1;
    }

    // Record personnel.
    bestStreak.value = math.max(bestStreak.value, currentStreak.value);

    // Mémorise aujourd'hui (date + pastille de la semaine).
    lastCheckIn.value = today;
    _checkedDays.add(_isoDate(today));
    _pruneToCurrentWeek();

    await _persistAll();
  }

  // ── Persistance ────────────────────────────────────────────────────────────
  Future<void> _persistAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCurrentStreak, currentStreak.value);
    await prefs.setInt(_kBestStreak, bestStreak.value);
    final last = lastCheckIn.value;
    if (last != null) {
      await prefs.setString(_kLastCheckIn, _isoDate(last));
    }
    await prefs.setStringList(_kCheckedDays, _checkedDays.toList());
  }

  Future<void> _persistCheckedDays() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kCheckedDays, _checkedDays.toList());
  }

  // ── Helpers dates ──────────────────────────────────────────────────────────
  /// Lundi (00:00) de la semaine courante. `weekday` : 1 = lundi … 7 = dimanche.
  DateTime _mondayOfCurrentWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.subtract(Duration(days: today.weekday - 1));
  }

  /// Élague [_checkedDays] aux 7 jours de la semaine courante (Lun→Dim) pour
  /// éviter une croissance illimitée du cache.
  void _pruneToCurrentWeek() {
    final monday = _mondayOfCurrentWeek();
    final validIso = <String>{
      for (var i = 0; i < 7; i++) _isoDate(monday.add(Duration(days: i))),
    };
    _checkedDays.removeWhere((d) => !validIso.contains(d));
  }

  /// Format date ISO court `yyyy-MM-dd` (sans heure) — clé stable de jour.
  String _isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
