import 'package:flutter/material.dart';

class AppRoleColors extends ThemeExtension<AppRoleColors> {
  final Color managerBg;
  final Color managerText;
  final Color receptionBg;
  final Color receptionText;
  final BorderRadius badgeRadius;

  const AppRoleColors({
    required this.managerBg,
    required this.managerText,
    required this.receptionBg,
    required this.receptionText,
    this.badgeRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  AppRoleColors copyWith({
    Color? managerBg,
    Color? managerText,
    Color? receptionBg,
    Color? receptionText,
    BorderRadius? badgeRadius,
  }) {
    return AppRoleColors(
      managerBg: managerBg ?? this.managerBg,
      managerText: managerText ?? this.managerText,
      receptionBg: receptionBg ?? this.receptionBg,
      receptionText: receptionText ?? this.receptionText,
      badgeRadius: badgeRadius ?? this.badgeRadius,
    );
  }

  @override
  AppRoleColors lerp(ThemeExtension<AppRoleColors>? other, double t) {
    if (other is! AppRoleColors) return this;
    return AppRoleColors(
      managerBg: Color.lerp(managerBg, other.managerBg, t) ?? managerBg,
      managerText: Color.lerp(managerText, other.managerText, t) ?? managerText,
      receptionBg: Color.lerp(receptionBg, other.receptionBg, t) ?? receptionBg,
      receptionText: Color.lerp(receptionText, other.receptionText, t) ?? receptionText,
      badgeRadius: BorderRadius.lerp(badgeRadius, other.badgeRadius, t) ?? badgeRadius,
    );
  }
}

// New modern UI colors extension
class ModernUIColors extends ThemeExtension<ModernUIColors> {
  final Color glassBg;
  final Color glassStroke;
  final Color hoverBg;
  final Color activeBg;
  final Color shimmerBase;
  final Color shimmerHighlight;
  final Color gradientStart;
  final Color gradientEnd;
  final Color accentGlow;
  final Color successBg;
  final Color successText;
  final Color warningBg;
  final Color warningText;
  final Color infoBg;
  final Color infoText;

  const ModernUIColors({
    required this.glassBg,
    required this.glassStroke,
    required this.hoverBg,
    required this.activeBg,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.gradientStart,
    required this.gradientEnd,
    required this.accentGlow,
    required this.successBg,
    required this.successText,
    required this.warningBg,
    required this.warningText,
    required this.infoBg,
    required this.infoText,
  });

  @override
  ModernUIColors copyWith({
    Color? glassBg,
    Color? glassStroke,
    Color? hoverBg,
    Color? activeBg,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? gradientStart,
    Color? gradientEnd,
    Color? accentGlow,
    Color? successBg,
    Color? successText,
    Color? warningBg,
    Color? warningText,
    Color? infoBg,
    Color? infoText,
  }) {
    return ModernUIColors(
      glassBg: glassBg ?? this.glassBg,
      glassStroke: glassStroke ?? this.glassStroke,
      hoverBg: hoverBg ?? this.hoverBg,
      activeBg: activeBg ?? this.activeBg,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      accentGlow: accentGlow ?? this.accentGlow,
      successBg: successBg ?? this.successBg,
      successText: successText ?? this.successText,
      warningBg: warningBg ?? this.warningBg,
      warningText: warningText ?? this.warningText,
      infoBg: infoBg ?? this.infoBg,
      infoText: infoText ?? this.infoText,
    );
  }

  @override
  ModernUIColors lerp(ThemeExtension<ModernUIColors>? other, double t) {
    if (other is! ModernUIColors) return this;
    return ModernUIColors(
      glassBg: Color.lerp(glassBg, other.glassBg, t) ?? glassBg,
      glassStroke: Color.lerp(glassStroke, other.glassStroke, t) ?? glassStroke,
      hoverBg: Color.lerp(hoverBg, other.hoverBg, t) ?? hoverBg,
      activeBg: Color.lerp(activeBg, other.activeBg, t) ?? activeBg,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t) ?? shimmerBase,
      shimmerHighlight: Color.lerp(shimmerHighlight, other.shimmerHighlight, t) ?? shimmerHighlight,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t) ?? gradientStart,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t) ?? gradientEnd,
      accentGlow: Color.lerp(accentGlow, other.accentGlow, t) ?? accentGlow,
      successBg: Color.lerp(successBg, other.successBg, t) ?? successBg,
      successText: Color.lerp(successText, other.successText, t) ?? successText,
      warningBg: Color.lerp(warningBg, other.warningBg, t) ?? warningBg,
      warningText: Color.lerp(warningText, other.warningText, t) ?? warningText,
      infoBg: Color.lerp(infoBg, other.infoBg, t) ?? infoBg,
      infoText: Color.lerp(infoText, other.infoText, t) ?? infoText,
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    notifyListeners();
  }

  // Light Theme
  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: const Color(0xFF2563EB),
      onPrimary: Colors.white,
      secondary: const Color(0xFF6366F1),
      onSecondary: Colors.white,
      tertiary: const Color(0xFF06B6D4), // cyan
      onTertiary: Colors.white,
      error: const Color(0xFFEF4444),
      onError: Colors.white,
      surface: const Color(0xFFFFFBFF),
      onSurface: const Color(0xFF1C1B1F),
      outline: const Color(0xFF79747E),
      outlineVariant: const Color(0xFFCAC4D0),
      shadow: Colors.black.withOpacity(0.08),
      surfaceContainerHighest: const Color(0xFFE6E0E9),
      inverseSurface: const Color(0xFF313033),
      inversePrimary: const Color(0xFFBEBEFF),
      scrim: Colors.black.withOpacity(0.32),
    ),
    scaffoldBackgroundColor: const Color(0xFFFAFAFC),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      color: const Color(0xFFFFFBFF),
      margin: const EdgeInsets.all(8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE1E5E9)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE1E5E9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        shadowColor: Colors.transparent,
      ),
    ),
    extensions: const <ThemeExtension<dynamic>>[
      AppRoleColors(
        managerBg: Color(0xFFDCFCE7),
        managerText: Color(0xFF166534),
        receptionBg: Color(0xFFFEF3C7),
        receptionText: Color(0xFF92400E),
      ),
      ModernUIColors(
        glassBg: Color(0xF0FFFFFF),
        glassStroke: Color(0x20000000),
        hoverBg: Color(0x08000000),
        activeBg: Color(0x12000000),
        shimmerBase: Color(0xFFF1F5F9),
        shimmerHighlight: Color(0xFFFFFFFF),
        gradientStart: Color(0xFF667EEA),
        gradientEnd: Color(0xFF764BA2),
        accentGlow: Color(0xFF2563EB),
        successBg: Color(0xFFDCFCE7),
        successText: Color(0xFF166534),
        warningBg: Color(0xFFFEF3C7),
        warningText: Color(0xFF92400E),
        infoBg: Color(0xFFDBEAFE),
        infoText: Color(0xFF1E40AF),
      ),
    ],
  );

  // Dark Theme
  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: const Color(0xFF4F83FF),
      onPrimary: const Color(0xFF002A77),
      secondary: const Color(0xFF8B92FF),
      onSecondary: const Color(0xFF1A1D5D),
      tertiary: const Color(0xFF5EEAD4),
      onTertiary: const Color(0xFF00382E),
      error: const Color(0xFFFF5449),
      onError: const Color(0xFF690005),
      surface: const Color(0xFF0F1419),
      onSurface: const Color(0xFFE4E1E6),
      outline: const Color(0xFF938F99),
      outlineVariant: const Color(0xFF49454F),
      shadow: Colors.black.withOpacity(0.4),
      surfaceContainerHighest: const Color(0xFF36343B),
      inverseSurface: const Color(0xFFE4E1E6),
      inversePrimary: const Color(0xFF2563EB),
      scrim: Colors.black.withOpacity(0.5),
    ),
    scaffoldBackgroundColor: const Color(0xFF0B0F14),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF2A2D31)),
      ),
      color: const Color(0xFF1A1D23),
      margin: const EdgeInsets.all(8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A1D23),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2A2D31)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2A2D31)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF4F83FF), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF5449)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF5449), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: const Color(0xFF4F83FF),
        foregroundColor: Colors.white,
        shadowColor: Colors.transparent,
      ),
    ),
    extensions: const <ThemeExtension<dynamic>>[
      AppRoleColors(
        managerBg: Color(0xFF1F4A2C),
        managerText: Color(0xFF7EE3A3),
        receptionBg: Color(0xFF4A3A1A),
        receptionText: Color(0xFFFFD768),
      ),
      ModernUIColors(
        glassBg: Color(0xD91A1D23),
        glassStroke: Color(0x20FFFFFF),
        hoverBg: Color(0x08FFFFFF),
        activeBg: Color(0x12FFFFFF),
        shimmerBase: Color(0xFF2A2D31),
        shimmerHighlight: Color(0xFF3A3D41),
        gradientStart: Color(0xFF1E40AF),
        gradientEnd: Color(0xFF7C3AED),
        accentGlow: Color(0xFF4F83FF),
        successBg: Color(0xFF1F4A2C),
        successText: Color(0xFF7EE3A3),
        warningBg: Color(0xFF4A3A1A),
        warningText: Color(0xFFFFD768),
        infoBg: Color(0xFF1E3A8A),
        infoText: Color(0xFF93C5FD),
      ),
    ],
  );
}