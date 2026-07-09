import 'package:flutter/material.dart';

/// Ne monte un onglet qu'après la première visite — évite 5 écrans + APIs au boot.
class HomeLazyTabStack extends StatefulWidget {
  const HomeLazyTabStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<HomeLazyTabStack> createState() => _HomeLazyTabStackState();
}

class _HomeLazyTabStackState extends State<HomeLazyTabStack> {
  final Set<int> _mountedTabs = {0};

  @override
  void didUpdateWidget(covariant HomeLazyTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _mountedTabs.add(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    _mountedTabs.add(widget.index);
    return Stack(
      fit: StackFit.expand,
      children: List.generate(widget.children.length, (i) {
        if (!_mountedTabs.contains(i)) {
          return const SizedBox.shrink();
        }
        final active = i == widget.index;
        return Offstage(
          offstage: !active,
          child: TickerMode(
            enabled: active,
            child: widget.children[i],
          ),
        );
      }),
    );
  }
}
