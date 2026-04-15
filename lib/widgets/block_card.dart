import 'package:flutter/material.dart';

import '../models/block.dart';

class BlockCard extends StatelessWidget {
  final Block block;
  final bool completed;
  final bool isCurrent;
  final VoidCallback onToggle;
  final VoidCallback? onLongPress;

  const BlockCard({
    super.key,
    required this.block,
    required this.completed,
    required this.isCurrent,
    required this.onToggle,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = block.priority.color;

    final bg = isCurrent
        ? color.withOpacity(0.10)
        : completed
            ? cs.surfaceContainerLow
            : cs.surfaceContainer;
    final borderColor =
        isCurrent ? color.withOpacity(0.6) : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onToggle,
          onLongPress: onLongPress,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 1.5),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TimeColumn(
                  start: block.startLabel,
                  end: block.endLabel,
                  color: color,
                  muted: completed,
                ),
                const SizedBox(width: 14),
                Container(
                  width: 3,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(completed ? 0.3 : 1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              block.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                decoration: completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: completed
                                    ? cs.onSurfaceVariant
                                    : cs.onSurface,
                              ),
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 6),
                            _pulsingDot(color),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _Chip(
                            label: block.priority.label,
                            color: color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${block.durationMinutes} min',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (block.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          block.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _CheckButton(
                  completed: completed,
                  color: color,
                  onTap: onToggle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pulsingDot(Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (_, v, __) => Opacity(
        opacity: v,
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
      onEnd: () {}, // Not looping without statefulness, kept simple
    );
  }
}

class _TimeColumn extends StatelessWidget {
  final String start;
  final String end;
  final Color color;
  final bool muted;
  const _TimeColumn(
      {required this.start,
      required this.end,
      required this.color,
      required this.muted});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
          fontWeight: FontWeight.w700,
          color: muted
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : color,
          letterSpacing: -0.3,
        );
    return SizedBox(
      width: 46,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(start, style: base),
          const SizedBox(height: 2),
          Text(
            end,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  final bool completed;
  final Color color;
  final VoidCallback onTap;
  const _CheckButton(
      {required this.completed, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: completed ? color : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: completed ? color : cs.outline,
            width: 2,
          ),
        ),
        child: completed
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
            : null,
      ),
    );
  }
}
