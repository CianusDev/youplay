import 'package:flutter/material.dart';

import '../../theme/sika_tokens.dart';
import 'cover_art.dart';

/// Tuile d'accès rapide (grille 2 colonnes de l'accueil).
class QuickPickTile extends StatelessWidget {
  const QuickPickTile({super.key, required this.title, required this.seed, this.imageUrl, this.variant, this.onTap});
  final String title;
  final String seed;
  final String? imageUrl;
  final int? variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SikaColors.surface,
      borderRadius: BorderRadius.circular(SikaRadius.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              CoverArt(variant: variant ?? CoverArt.variantFor(seed), size: 56, radius: 0, imageUrl: imageUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: SikaText.quickPick),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte de mix 148 (carrousel horizontal).
class MixCard extends StatelessWidget {
  const MixCard({super.key, required this.title, required this.subtitle, required this.seed, this.imageUrl, this.variant, this.onTap});
  final String title;
  final String subtitle;
  final String seed;
  final String? imageUrl;
  final int? variant;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 148,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CoverArt(variant: variant ?? CoverArt.variantFor(seed), size: 148, radius: SikaRadius.md, imageUrl: imageUrl),
            const SizedBox(height: 10),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: SikaText.cardTitle),
            const SizedBox(height: 2),
            Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: SikaText.meta.copyWith(height: 1.35)),
          ],
        ),
      ),
    );
  }
}

class ArtistBubble extends StatelessWidget {
  const ArtistBubble({super.key, required this.name, required this.seed, this.imageUrl, this.onTap});
  final String name;
  final String seed;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 92,
        child: Column(
          children: [
            CoverArt.seeded(seed, size: 92, circle: true, imageUrl: imageUrl),
            const SizedBox(height: 8),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: SikaText.ui(12, w: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Titre de section + lien optionnel ("Tout voir").
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.padding = const EdgeInsets.fromLTRB(20, 28, 20, 12), this.small = false});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsets padding;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(child: Text(title, style: small ? SikaText.h2Small : SikaText.h2Section, overflow: TextOverflow.ellipsis)),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 3),
                child: Text(action!, style: SikaText.ui(12, w: FontWeight.w700, color: SikaColors.textMuted)),
              ),
            ),
        ],
      ),
    );
  }
}
