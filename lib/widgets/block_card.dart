import 'package:flutter/material.dart';

import '../models/block.dart';
import '../models/category.dart';
import 'glass.dart';

class BlockCard extends StatelessWidget {
  final Block block;
  final AppCategory? category;
  final bool completed;
  final bool isCurrent;
  final VoidCallback onToggle;
  final VoidCallback? onLongPress;

  const BlockCard({
    super.key,
    required this.block,
    required this.category,
    required this.completed,
    required this.isCurrent,
    required this.onToggle,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = category?.color ?? cs.primary;
    final dark = theme.brightness == Brightness.dark;

    final tint = isCurrent
        ? color.withOpacity(dark ? 0.18 : 0.20)
        : completed
            ? (dark
                ? Colors.white.withOpacity(0.03)
                : Colors.white.withOpacity(0.35))
            : (dark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.55));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: GestureDetector(
        onTap: onToggle,
        onLongPress: onLongPress,
        child: Glass(
          borderRadius: BorderRadius.circular(22),
          tint: tint,
          opacity: 1,
          blur: 20,
          border: Border.all(
            color: isCurrent
                ? color.withOpacity(0.55)
                : (dark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.6)),
            width: isCurrent ? 1.5 : 1,
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _IconBubble(
                color: color,
                icon: category?.icon ?? Icons.schedule_rounded,
                dim: completed,
              ),
              const SizedBox(width: 12),
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
                        if (isCurrent) _LiveDot(color: color),
                      ],
                    ),
                    const SizedBox(height: 4),
                    DefaultTextStyle(
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: cs.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      child: Row(
                        children: [
                          Text(block.rangeLabel),
                          Text('  •  ${block.durationMinutes} min'),
                          if (category != null) ...[
                            const SizedBox(width: 8),
                            _CategoryPill(
                              name: category!.name,
                              color: color,
                            ),
                          ],
                        ],
                      ),
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
              _CheckButton(completed: completed, color: color, onTap: onToggle),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool dim;
  const _IconBubble(
      {required this.color, required this.icon, required this.dim});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(dim ? 0.18 : 0.35),
            color.withOpacity(dim ? 0.08 : 0.18),
          ],
        ),
        border: Border.all(color: color.withOpacity(dim ? 0.25 : 0.5)),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String name;
  final Color color;
  const _CategoryPill({required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35), width: 0.8),
      ),
      child: Text(
        name,
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

class _LiveDot extends StatefulWidget {
  final Color color;
  const _LiveDot({required this.color});
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))
        ..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(0.4 + _c.value * 0.6),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.5 * _c.value),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
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
            color: completed ? color : cs.outline.withOpacity(0.6),
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
