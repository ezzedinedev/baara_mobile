import 'package:flutter/material.dart';
import 'skeleton_box.dart';


class ChatMessagesSkeleton extends StatelessWidget {
  const ChatMessagesSkeleton({super.key, this.itemCount = 7});

  final int itemCount;

  static const _widths = <double>[0.55, 0.40, 0.70, 0.48, 0.62, 0.34, 0.58];

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final mine = index.isOdd;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Align(
            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
            child: SkeletonBox(
              width: maxWidth * _widths[index % _widths.length],
              height: 44,
              radius: 18,
            ),
          ),
        );
      },
    );
  }
}
