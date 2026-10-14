// Sika — design tokens (source de vérité pour l'implémentation Flutter)
// Toutes les valeurs sont en logical pixels (1 px CSS de la maquette = 1 dp Flutter).
// Maquette de référence : 390 × 844 (iPhone 14/15).
//
// Dépendance : google_fonts: ^6.2.1

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SikaColors {
  SikaColors._();

  // Marque
  static const yellow = Color(0xFFFFD60A); // primaire — action principale, sélection, titre en cours
  static const yellowSoft = Color(0xFFFFE878); // hover / tuile "Traditionnel"
  static const onYellow = Color(0xFF141208); // texte/icônes sur jaune
  static const orange = Color(0xFFFF7A1A); // accent secondaire (pochettes, halo lecteur)

  // Fonds & surfaces (sombre chaud)
  static const bg = Color(0xFF0F0E0B); // fond d'écran
  static const surface = Color(0xFF1A1915); // cartes, lignes au survol, accès rapides
  static const surface2 = Color(0xFF24221C); // chips inactifs, pistes, séparateurs
  static const surface3 = Color(0xFF2A271E); // mini-lecteur
  static const navBorder = Color(0xFF1F1D17); // bordure haute de la nav
  static const track = Color(0xFF3A372D); // piste inactive (progress, switch off, waveform)
  static const radioOff = Color(0xFF5A5547); // bordure radio inactive, segment stockage

  // Texte
  static const text = Color(0xFFF6F3EA); // texte principal
  static const textSoft = Color(0xFFC9C3B3); // texte secondaire sur surfaces élevées
  static const textMuted = Color(0xFFA39E8F); // méta, légendes (≥ 4.5:1 sur bg)
  static const placeholder = Color(0xFF6B6659);

  // Pochettes / tuiles
  static const forest = Color(0xFF1F3B2D);
  static const cream = Color(0xFFF1E6C8);
  static const plum = Color(0xFF3A2A55);
  static const wine = Color(0xFF8A1C1C);

  // Navigation (fond semi-opaque)
  static const navBg = Color(0xF50F0E0B); // rgba(15,14,11,0.96)
}

class SikaRadius {
  SikaRadius._();
  static const xs = 8.0; // petites pochettes (44–46), badges
  static const sm = 10.0; // accès rapides, pochettes liste 56–60
  static const md = 14.0; // mini-lecteur, cartes mix (148), champ recherche
  static const lg = 18.0; // cartes info, pochette playlist
  static const xl = 22.0; // pochette lecteur (342), cartes paroles/artiste, cartes réglages
  static const xxl = 24.0; // carte "Radio", widgets iOS
  static const pill = 999.0; // chips, boutons ronds
  static const sheetBottom = 32.0; // bas de l'en-tête jaune Playlist
  static const device = 44.0; // coin de l'écran (artboard)
}

class SikaSpace {
  SikaSpace._();
  static const gutter = 20.0; // marge latérale de toutes les pages (Lecteur : 24)
  static const playerGutter = 24.0;
  static const topSafe = 58.0; // padding-top contenu (54 pour Lecteur & Playlist)
  static const sectionGap = 28.0; // entre sections de l'accueil
  static const titleToContent = 12.0;
  static const gridGap = 8.0;
  static const navHeight = 88.0; // inclut 22 de home indicator
  static const miniPlayerBottom = 92.0; // distance bas écran → bas mini-lecteur
  static const miniPlayerInset = 8.0; // marge gauche/droite du mini-lecteur
  static const minTouch = 44.0;
}

class SikaShadows {
  SikaShadows._();
  static const miniPlayer = [BoxShadow(color: Color(0x80000000), blurRadius: 30, offset: Offset(0, 12))];
  static const playerCover = [BoxShadow(color: Color(0x8C000000), blurRadius: 60, offset: Offset(0, 30))];
  static const playButton = [BoxShadow(color: Color(0x47FFD60A), blurRadius: 30, offset: Offset(0, 10))];
  static const playlistCover = [BoxShadow(color: Color(0x59141208), blurRadius: 36, offset: Offset(0, 18))];
}

/// Typo : Bricolage Grotesque (display, titres) + Manrope (UI, texte).
/// letterSpacing en px (= valeur CSS), height = line-height / font-size.
class SikaText {
  SikaText._();

  static TextStyle display(double size, {FontWeight w = FontWeight.w800, double ls = 0, double? height, Color color = SikaColors.text}) =>
      GoogleFonts.bricolageGrotesque(fontSize: size, fontWeight: w, letterSpacing: ls, height: height, color: color);

  static TextStyle ui(double size, {FontWeight w = FontWeight.w500, double ls = 0, double? height, Color color = SikaColors.text}) =>
      GoogleFonts.manrope(fontSize: size, fontWeight: w, letterSpacing: ls, height: height, color: color);

  // Échelle utilisée dans la maquette
  static final h1Page = display(30, ls: -1); // "Téléchargés" (Recherche : 32, Biblio : 26 ls -0.8)
  static final h1Player = display(28, ls: -0.6, height: 1.1); // titre du morceau
  static final h1Playlist = display(32, ls: -1, height: 0.98);
  static final heroCard = display(26, ls: -0.6, height: 1.05); // "Ta Radio Sika"
  static final h2Section = display(21, w: FontWeight.w700, ls: -0.4); // "Tes mix du jour"
  static final h2Small = display(16, w: FontWeight.w700); // "Recherches récentes"
  static final userName = display(20, w: FontWeight.w700, ls: -0.3);
  static final tile = display(17, ls: -0.3, height: 1.1); // tuiles genre
  static final lyricsCurrent = display(23, height: 1.3);
  static final lyricsOther = display(21, w: FontWeight.w700, height: 1.35); // opacity 0.4

  static final rowTitle = ui(15, w: FontWeight.w700);
  static final cardTitle = ui(14, w: FontWeight.w700);
  static final quickPick = ui(13, w: FontWeight.w700, height: 1.2);
  static final chip = ui(13, w: FontWeight.w600);
  static final meta = ui(12, color: SikaColors.textMuted);
  static final eyebrow = ui(11, w: FontWeight.w700, ls: 1.4); // MAJUSCULES
  static final navLabel = ui(11, w: FontWeight.w600);
  static final time = ui(13, w: FontWeight.w800, color: SikaColors.yellow); // tabular figures
}

ThemeData sikaTheme() => ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: SikaColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: SikaColors.yellow,
        onPrimary: SikaColors.onYellow,
        secondary: SikaColors.orange,
        surface: SikaColors.surface,
        onSurface: SikaColors.text,
      ),
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
      splashFactory: InkSparkle.splashFactory,
    );
