import 'package:flutter/material.dart';

import '../../theme/sika_tokens.dart';
import 'sika_icon.dart';

class SikaChip extends StatelessWidget {
  const SikaChip({super.key, required this.label, this.selected = false, this.onTap, this.icon, this.background, this.padding = 16});
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final String? icon;
  final Color? background;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? SikaColors.onYellow : SikaColors.text;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? SikaColors.yellow : (background ?? SikaColors.surface2),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 36,
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[SikaIcon(icon!, size: 14, color: SikaColors.textMuted), const SizedBox(width: 6)],
                Text(label, style: SikaText.chip.copyWith(color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rangée horizontale de chips à sélection unique.
class ChipRow extends StatelessWidget {
  const ChipRow({super.key, required this.labels, required this.selected, required this.onSelect, this.padding = const EdgeInsets.symmetric(horizontal: SikaSpace.gutter)});
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => SikaChip(label: labels[i], selected: i == selected, onTap: () => onSelect(i)),
      ),
    );
  }
}
