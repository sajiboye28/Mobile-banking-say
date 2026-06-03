import 'package:flutter/material.dart';

/// Sovereign Vault — Design System Colors
/// Matches the stitch/nexus_obsidian/DESIGN.md spec exactly.
abstract class AppColors {
  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF131313);
  static const Color surfaceContainerLowest = Color(0xFF0E0E0E);
  static const Color surfaceContainerLow = Color(0xFF1C1B1B);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceContainerHigh = Color(0xFF2A2A2A);
  static const Color surfaceContainerHighest = Color(0xFF353534);
  static const Color surfaceBright = Color(0xFF3A3939);

  // ── Primary ───────────────────────────────────────────────────────────────
  /// Light lavender — used as text / icon tint on dark surfaces
  static const Color primary = Color(0xFFB7C4FF);

  /// Electric blue — used for CTAs, hero gradients, active nav pills
  static const Color primaryContainer = Color(0xFF0052FF);
  static const Color onPrimary = Color(0xFF002682);
  static const Color onPrimaryFixed = Color(0xFF001452);
  static const Color onPrimaryContainer = Color(0xFFDFE3FF);
  static const Color primaryFixed = Color(0xFFDDE1FF);
  static const Color primaryFixedDim = Color(0xFFB7C4FF);
  static const Color inversePrimary = Color(0xFF004CED);

  // ── Secondary ─────────────────────────────────────────────────────────────
  static const Color secondary = Color(0xFFB7C4FF);
  static const Color secondaryContainer = Color(0xFF2B418F);
  static const Color onSecondary = Color(0xFF0E2977);
  static const Color onSecondaryContainer = Color(0xFF9FB1FF);
  static const Color secondaryFixed = Color(0xFFDDE1FF);
  static const Color secondaryFixedDim = Color(0xFFB7C4FF);
  static const Color onSecondaryFixed = Color(0xFF001452);
  static const Color onSecondaryFixedVariant = Color(0xFF2B418F);

  // ── Text / On-surface ─────────────────────────────────────────────────────
  static const Color onSurface = Color(0xFFE5E2E1);
  static const Color onSurfaceVariant = Color(0xFFC3C5D9);
  static const Color onBackground = Color(0xFFE5E2E1);
  static const Color inverseSurface = Color(0xFFE5E2E1);
  static const Color inverseOnSurface = Color(0xFF313030);

  // ── Outline ───────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFF8D90A2);

  /// Ghost border — used at 20% opacity
  static const Color outlineVariant = Color(0xFF434656);

  // ── State ─────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onError = Color(0xFF690005);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // ── Semantic convenience ─────────────────────────────────────────────────
  static const Color success = Color(0xFF4ADE80);
  static const Color successDim = Color(0xFF16A34A);
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningDim = Color(0xFFD97706);

  // ── Gradients ─────────────────────────────────────────────────────────────
  /// Electric gradient — the "soul" of the brand
  static const LinearGradient electricGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryContainer, primary],
  );

  /// Hero card glass background
  static LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      surfaceContainerHigh.withOpacity(0.4),
      surfaceContainerLow.withOpacity(0.2),
    ],
  );
}
