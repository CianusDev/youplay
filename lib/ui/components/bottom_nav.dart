import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/sika_tokens.dart';
import 'sika_icon.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  static const items = [
    ('Accueil', 'home', 'home-filled'),
    ('Recherche', 'search', 'search'),
    ('Bibliothèque', 'library', 'library'),
    ('Téléchargés', 'download-circle', 'download-circle-filled'),
  ];

  /// Hauteur totale (contenu 66 + safe area basse, min 22 comme la maquette).
  static double heightOf(BuildContext context) => 66 + bottomInset(context);
  static double bottomInset(BuildContext context) => MediaQuery.viewPaddingOf(context).bottom.clamp(12.0, 34.0);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: const BoxDecoration(
            color: SikaColors.navBg,
            border: Border(top: BorderSide(color: SikaColors.navBorder)),
          ),
          padding: EdgeInsets.fromLTRB(12, 8, 12, bottomInset(context)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                Semantics(
                  button: true,
                  selected: i == index,
                  label: items[i].$1,
                  excludeSemantics: true,
                  child: InkResponse(
                    onTap: () => onTap(i),
                    radius: 40,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 64),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SikaIcon(
                              i == index ? items[i].$3 : items[i].$2,
                              size: 24,
                              color: i == index ? SikaColors.yellow : SikaColors.textMuted,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              items[i].$1,
                              style: SikaText.navLabel.copyWith(color: i == index ? SikaColors.yellow : SikaColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
