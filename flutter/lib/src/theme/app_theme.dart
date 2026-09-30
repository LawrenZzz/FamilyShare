import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class FamilyShareTheme {
  static const seedColor = Color(0xFF0F766E);

  static const glassTheme = GlassThemeData(
    light: GlassThemeVariant(
      settings: GlassThemeSettings(
        glassColor: Color(0x30F4FFFC),
        thickness: 26,
        blur: 7,
        saturation: 1.35,
        refractiveIndex: 1.18,
        lightIntensity: 0.9,
        ambientStrength: 0.16,
        chromaticAberration: 0.02,
        edgeAbsorption: 0.02,
        rimShade: 0.2,
        rimLight: 0.65,
      ),
    ),
    dark: GlassThemeVariant(
      settings: GlassThemeSettings(
        glassColor: Color(0x26142629),
        thickness: 28,
        blur: 8,
        saturation: 1.2,
        refractiveIndex: 1.2,
        lightIntensity: 0.75,
        ambientStrength: 0.08,
        chromaticAberration: 0.015,
        edgeAbsorption: 0.025,
        rimShade: 0.35,
        rimLight: 0.85,
      ),
    ),
  );

  static ThemeData light() => _theme(Brightness.light);

  static ThemeData dark() => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final generated = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    final scheme = generated.copyWith(
      surface: dark ? const Color(0xFF0E1517) : const Color(0xFFF5F9F8),
      onSurface: dark ? const Color(0xFFE7F1EF) : const Color(0xFF102725),
      surfaceContainerLowest:
          dark ? const Color(0xFF091011) : const Color(0xFFFFFFFF),
      surfaceContainerLow:
          dark ? const Color(0xFF121B1D) : const Color(0xFFF2F7F6),
      surfaceContainer:
          dark ? const Color(0xFF172123) : const Color(0xFFEAF2F0),
      surfaceContainerHigh:
          dark ? const Color(0xFF1D292B) : const Color(0xFFE1ECE9),
      surfaceContainerHighest:
          dark ? const Color(0xFF253234) : const Color(0xFFD6E5E1),
      outline: dark ? const Color(0xFF80918F) : const Color(0xFF667A77),
      outlineVariant: dark ? const Color(0xFF344442) : const Color(0xFFC3D2CF),
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: scheme.scrim.withValues(alpha: dark ? 0.58 : 0.32),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.7),
        thickness: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  static LiquidGlassSettings mapGlassSettings(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LiquidGlassSettings(
      glassColor: dark ? const Color(0x40111F22) : const Color(0x4DF5FCFA),
      platformViewFallbackColor:
          dark ? const Color(0xC5162224) : const Color(0xC7F5FBF9),
      platformViewMode: PlatformViewGlassMode.passthrough,
      blur: dark ? 9 : 8,
      thickness: dark ? 30 : 28,
      saturation: dark ? 1.18 : 1.38,
      refractiveIndex: 1.2,
      lightIntensity: dark ? 0.72 : 0.92,
      ambientStrength: dark ? 0.08 : 0.16,
      ambientRim: dark ? 0.08 : 0.14,
      chromaticAberration: dark ? 0.012 : 0.022,
      specularSharpness: GlassSpecularSharpness.sharp,
      edgeAbsorption: dark ? 0.03 : 0.018,
      rimShade: dark ? 0.38 : 0.2,
      rimShadeEnds: 0.12,
      rimLight: dark ? 0.9 : 0.7,
      shadowElevation: dark ? 1.5 : 2.5,
    );
  }

  static LiquidGlassSettings overlayGlassSettings(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LiquidGlassSettings(
      glassColor: dark ? const Color(0xA8182426) : const Color(0xB8F7FBFA),
      platformViewFallbackColor:
          dark ? const Color(0xE8182426) : const Color(0xE8F7FBFA),
      blur: 14,
      thickness: 30,
      saturation: dark ? 1.12 : 1.25,
      refractiveIndex: 1.18,
      lightIntensity: dark ? 0.68 : 0.88,
      ambientStrength: dark ? 0.08 : 0.15,
      ambientRim: dark ? 0.1 : 0.16,
      chromaticAberration: 0.015,
      specularSharpness: GlassSpecularSharpness.medium,
      edgeAbsorption: dark ? 0.035 : 0.02,
      rimShade: dark ? 0.4 : 0.22,
      rimLight: dark ? 0.9 : 0.72,
      shadowElevation: 4,
    );
  }
}
