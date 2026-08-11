import 'package:flutter/material.dart';
import 'package:baara/app/core/theme/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../utils/haptics.dart';

/// FAB qui apparait apres ~300px de scroll et ramene en haut.
/// Branche un [ScrollController] et l'utilise pour piloter visibilite + scroll.
class ScrollToTopFab extends StatefulWidget {
  const ScrollToTopFab({
    super.key,
    required this.controller,
    this.threshold = 300,
  });

  final ScrollController controller;
  final double threshold;

  @override
  State<ScrollToTopFab> createState() => _ScrollToTopFabState();
}

class _ScrollToTopFabState extends State<ScrollToTopFab> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final shouldShow = widget.controller.hasClients &&
        widget.controller.offset > widget.threshold;
    if (shouldShow != _visible) {
      setState(() => _visible = shouldShow);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 2),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: IgnorePointer(
          ignoring: !_visible,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                AppHaptics.tap();
                widget.controller.animateTo(
                  0,
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                );
              },
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.32),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  AppIcons.arrowUp,
                  color: AppColors.onPrimary,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
