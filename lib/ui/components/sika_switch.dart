import 'package:flutter/material.dart';

import '../../theme/sika_tokens.dart';

class SikaSwitch extends StatelessWidget {
  const SikaSwitch({super.key, required this.value, required this.onChanged, this.label = ''});
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: label,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: SizedBox(
          width: 52,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 52,
              height: 32,
              decoration: BoxDecoration(color: value ? SikaColors.yellow : SikaColors.track, borderRadius: BorderRadius.circular(16)),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(color: value ? SikaColors.onYellow : SikaColors.text, shape: BoxShape.circle),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
