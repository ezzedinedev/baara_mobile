import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'package:jobaway/app/core/theme/app_colors.dart';
import 'package:jobaway/app/core/theme/app_text_styles.dart';
import 'package:jobaway/app/core/utils/haptics.dart';
import 'package:jobaway/app/core/widgets/widgets.dart';

/// Barre d'enregistrement vocal inline (remplace le composer pendant
/// l'enregistrement). Modèle familier WhatsApp/Telegram, deux issues claires :
/// **corbeille** (annule + supprime) à gauche, **envoyer** à droite. Le micro
/// démarre l'enregistrement dès l'ouverture — plus de « appuyez pour… ».
class VoiceRecorderWidget extends StatefulWidget {
  final void Function(String path) onSend;
  final VoidCallback? onCancel;

  const VoiceRecorderWidget({super.key, required this.onSend, this.onCancel});

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget>
    with SingleTickerProviderStateMixin {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  Duration _duration = Duration.zero;
  Timer? _timer;
  StreamSubscription<Amplitude>? _ampSub;
  String? _path;

  // Petit historique d'amplitudes (waveform défilante).
  static const _barCount = 28;
  final List<double> _levels = List<double>.filled(_barCount, 0.06);

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    // Sur web, l'enregistrement natif n'est pas dispo : repli fichier.
    if (!kIsWeb) {
      _startRecording();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ampSub?.cancel();
    _pulse.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      AppToast.error('Micro requis', 'Autorisez le micro pour enregistrer.');
      widget.onCancel?.call();
      return;
    }

    _path =
        '${Directory.systemTemp.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    try {
      await _recorder.start(const RecordConfig(), path: _path!);
      AppHaptics.tap();
      setState(() {
        _isRecording = true;
        _duration = Duration.zero;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_isRecording && mounted) {
          setState(() => _duration += const Duration(seconds: 1));
        }
      });
      _ampSub = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 120))
          .listen(_onAmplitude);
    } catch (e) {
      AppToast.error(
          'Enregistrement', "Impossible de démarrer l'enregistrement.");
      widget.onCancel?.call();
    }
  }

  void _onAmplitude(Amplitude amp) {
    if (!mounted) return;
    // amp.current ≈ dBFS (négatif). On normalise vers 0..1.
    final normalized = ((amp.current + 45) / 45).clamp(0.06, 1.0);
    setState(() {
      _levels.removeAt(0);
      _levels.add(normalized.toDouble());
    });
  }

  Future<void> _send() async {
    if (!_isRecording) return;
    _timer?.cancel();
    await _ampSub?.cancel();
    try {
      final path = await _recorder.stop();
      _isRecording = false;
      if (path != null) {
        AppHaptics.success();
        widget.onSend(path);
      } else {
        widget.onCancel?.call();
      }
    } catch (_) {
      AppToast.error(
          'Enregistrement', "L'enregistrement n'a pas pu être finalisé.");
      widget.onCancel?.call();
    }
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    await _ampSub?.cancel();
    AppHaptics.tap();
    try {
      if (_isRecording) await _recorder.stop();
    } catch (_) {}
    // Supprime le fichier temporaire jeté.
    final p = _path;
    if (p != null && !kIsWeb) {
      try {
        final f = File(p);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    _isRecording = false;
    widget.onCancel?.call();
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
    );
    if (result != null && result.files.single.path != null && mounted) {
      widget.onSend(result.files.single.path!);
    } else {
      widget.onCancel?.call();
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        boxShadow: AppColors.lightShadow,
      ),
      child: SafeArea(
        top: false,
        child: kIsWeb ? _buildWebFallback() : _buildRecordingBar(),
      ),
    );
  }

  Widget _buildRecordingBar() {
    return Row(
      children: [
        // Corbeille — annule et supprime.
        _RoundAction(
          icon: IconlyLight.delete,
          color: AppColors.errorAccent,
          background: AppColors.errorAccent.withValues(alpha: 0.12),
          tooltip: 'Annuler',
          onTap: _cancel,
        ),
        const SizedBox(width: 10),
        // Zone live : point pulsant + waveform + chrono.
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                FadeTransition(
                  opacity: Tween<double>(begin: 0.35, end: 1).animate(_pulse),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.errorAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _Waveform(levels: _levels)),
                const SizedBox(width: 12),
                Text(
                  _formatDuration(_duration),
                  style: AppTextStyles.labelLg.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.bodyColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Envoyer — stoppe et envoie.
        _RoundAction(
          icon: IconlyLight.send,
          color: AppColors.onPrimary,
          background: AppColors.primary,
          tooltip: 'Envoyer',
          onTap: _send,
        ),
      ],
    );
  }

  Widget _buildWebFallback() {
    return Row(
      children: [
        _RoundAction(
          icon: IconlyLight.close_square,
          color: AppColors.hintColor,
          background: AppColors.surfaceLow,
          tooltip: 'Fermer',
          onTap: () => widget.onCancel?.call(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: _pickAudioFile,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Icon(IconlyLight.upload,
                      color: AppColors.primaryAccent, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Sélectionner un fichier audio',
                    style: AppTextStyles.bodyMd
                        .copyWith(color: AppColors.bodyColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bouton circulaire d'action (corbeille / envoyer).
class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.color,
    required this.background,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = PressScale(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 22),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: button) : button;
  }
}

/// Waveform défilante simple, alimentée par les amplitudes du micro.
class _Waveform extends StatelessWidget {
  const _Waveform({required this.levels});
  final List<double> levels;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (final level in levels)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: (level * 26).clamp(3, 26),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
