import 'package:flutter/material.dart';

class PageIndicator extends StatefulWidget {
  final int pageCount;
  final int currentIndex;

  const PageIndicator({
    super.key,
    required this.pageCount,
    required this.currentIndex,
  });

  @override
  State<PageIndicator> createState() => _PageIndicatorState();
}

class _PageIndicatorState extends State<PageIndicator> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < widget.pageCount; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == widget.currentIndex
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}
