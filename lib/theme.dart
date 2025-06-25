import 'package:flutter/material.dart';

class AppRoleColors extends ThemeExtension<AppRoleColors> {
  final Color managerBg;
  final Color managerText;
  final Color salesPersonBg;
  final Color salesPersonText;
  final Color fitterBg;
  final Color fitterText;
  final BorderRadius badgeRadius;

  const AppRoleColors({
    required this.managerBg,
    required this.managerText,
    required this.salesPersonBg,
    required this.salesPersonText,
    required this.fitterBg,
    required this.fitterText,
    this.badgeRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  AppRoleColors copyWith({
    Color? managerBg,
    Color? managerText,
    Color? salesPersonBg,
    Color? salesPersonText,
    Color? fitterBg,
    Color? fitterText,
    BorderRadius? badgeRadius,
  }) {
    return AppRoleColors(
      managerBg: managerBg ?? this.managerBg,
      managerText: managerText ?? this.managerText,
      salesPersonBg: salesPersonBg ?? this.salesPersonBg,
      salesPersonText: salesPersonText ?? this.salesPersonText,
      fitterBg: fitterBg ?? this.fitterBg,
      fitterText: fitterText ?? this.fitterText,
      badgeRadius: badgeRadius ?? this.badgeRadius,
    );
  }

  @override
  AppRoleColors lerp(ThemeExtension<AppRoleColors>? other, double t) {
    if (other is! AppRoleColors) return this;
    return AppRoleColors(
      managerBg: Color.lerp(managerBg, other.managerBg, t) ?? managerBg,
      managerText: Color.lerp(managerText, other.managerText, t) ?? managerText,
      salesPersonBg: Color.lerp(salesPersonBg, other.salesPersonBg, t) ?? salesPersonBg,
      salesPersonText: Color.lerp(salesPersonText, other.salesPersonText, t) ?? salesPersonText,
      fitterBg: Color.lerp(fitterBg, other.fitterBg, t) ?? fitterBg,
      fitterText: Color.lerp(fitterText, other.fitterText, t) ?? fitterText,
      badgeRadius: BorderRadius.lerp(badgeRadius, other.badgeRadius, t) ?? badgeRadius,
    );
  }
}

// Enhanced UI theme extension for consistent styling across all pages
class AppPageTheme extends ThemeExtension<AppPageTheme> {
  // Search bar styling
  final EdgeInsets searchBarPadding;
  final BorderRadius searchBarRadius;
  final double searchBarElevation;
  final Color searchBarFillColor;
  final EdgeInsets searchFieldPadding;
  
  // Card styling
  final double cardElevation;
  final BorderRadius cardRadius;
  final EdgeInsets cardPadding;
  final EdgeInsets cardMargin;
  
  // Table styling
  final EdgeInsets tableHeaderPadding;
  final EdgeInsets tableRowPadding;
  final double tableHeaderFontWeight;
  final double tableRowFontWeight;
  final Color tableHeaderBg;
  final Color tableEvenRowBg;
  final Color tableOddRowBg;
  final Color tableBorderColor;
  final double tableBorderOpacity;
  
  // Button styling
  final EdgeInsets buttonPadding;
  final BorderRadius buttonRadius;
  final double buttonElevation;
  final EdgeInsets iconButtonPadding;
  final BorderRadius iconButtonRadius;
  final double iconButtonSize;
  
  // Badge styling
  final EdgeInsets badgePadding;
  final BorderRadius badgeRadius;
  final double badgeWidth;
  final double badgeIconSize;
  final double badgeFontWeight;
  final double badgeLetterSpacing;
  
  // Serial number styling
  final EdgeInsets serialPadding;
  final BorderRadius serialRadius;
  final double serialWidth;
  final double serialFontWeight;
  
  // Empty state styling
  final double emptyIconSize;
  final double emptyIconOpacity;
  final EdgeInsets emptySpacing;
  
  // Pagination styling
  final EdgeInsets paginationPadding;
  final Color paginationBg;
  
  // Dialog styling
  final BorderRadius dialogRadius;
  final EdgeInsets dialogPadding;
  final double dialogMaxWidth;
  final EdgeInsets dialogFieldSpacing;
  
  // Shadow and elevation
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> buttonShadow;
  final List<BoxShadow> badgeShadow;

  const AppPageTheme({
    // Search bar
    this.searchBarPadding = const EdgeInsets.all(24.0),
    this.searchBarRadius = const BorderRadius.all(Radius.circular(12)),
    this.searchBarElevation = 0,
    this.searchBarFillColor = Colors.transparent,
    this.searchFieldPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    
    // Card
    this.cardElevation = 2,
    this.cardRadius = const BorderRadius.all(Radius.circular(16)),
    this.cardPadding = const EdgeInsets.all(16),
    this.cardMargin = const EdgeInsets.all(8),
    
    // Table
    this.tableHeaderPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    this.tableRowPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    this.tableHeaderFontWeight = 700,
    this.tableRowFontWeight = 600,
    this.tableHeaderBg = Colors.transparent,
    this.tableEvenRowBg = Colors.transparent,
    this.tableOddRowBg = Colors.transparent,
    this.tableBorderColor = Colors.grey,
    this.tableBorderOpacity = 0.1,
    
    // Button
    this.buttonPadding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    this.buttonRadius = const BorderRadius.all(Radius.circular(12)),
    this.buttonElevation = 0,
    this.iconButtonPadding = const EdgeInsets.all(8),
    this.iconButtonRadius = const BorderRadius.all(Radius.circular(8)),
    this.iconButtonSize = 18,
    
    // Badge
    this.badgePadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.badgeRadius = const BorderRadius.all(Radius.circular(20)),
    this.badgeWidth = 120,
    this.badgeIconSize = 16,
    this.badgeFontWeight = 600,
    this.badgeLetterSpacing = 0.3,
    
    // Serial
    this.serialPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.serialRadius = const BorderRadius.all(Radius.circular(6)),
    this.serialWidth = 50,
    this.serialFontWeight = 600,
    
    // Empty state
    this.emptyIconSize = 80,
    this.emptyIconOpacity = 0.3,
    this.emptySpacing = const EdgeInsets.symmetric(vertical: 12),
    
    // Pagination
    this.paginationPadding = const EdgeInsets.all(20.0),
    this.paginationBg = Colors.transparent,
    
    // Dialog
    this.dialogRadius = const BorderRadius.all(Radius.circular(16)),
    this.dialogPadding = const EdgeInsets.all(24.0),
    this.dialogMaxWidth = 420,
    this.dialogFieldSpacing = const EdgeInsets.only(bottom: 16),
    
    // Shadows
    this.cardShadow = const [],
    this.buttonShadow = const [],
    this.badgeShadow = const [],
  });

  @override
  AppPageTheme copyWith({
    EdgeInsets? searchBarPadding,
    BorderRadius? searchBarRadius,
    double? searchBarElevation,
    Color? searchBarFillColor,
    EdgeInsets? searchFieldPadding,
    double? cardElevation,
    BorderRadius? cardRadius,
    EdgeInsets? cardPadding,
    EdgeInsets? cardMargin,
    EdgeInsets? tableHeaderPadding,
    EdgeInsets? tableRowPadding,
    double? tableHeaderFontWeight,
    double? tableRowFontWeight,
    Color? tableHeaderBg,
    Color? tableEvenRowBg,
    Color? tableOddRowBg,
    Color? tableBorderColor,
    double? tableBorderOpacity,
    EdgeInsets? buttonPadding,
    BorderRadius? buttonRadius,
    double? buttonElevation,
    EdgeInsets? iconButtonPadding,
    BorderRadius? iconButtonRadius,
    double? iconButtonSize,
    EdgeInsets? badgePadding,
    BorderRadius? badgeRadius,
    double? badgeWidth,
    double? badgeIconSize,
    double? badgeFontWeight,
    double? badgeLetterSpacing,
    EdgeInsets? serialPadding,
    BorderRadius? serialRadius,
    double? serialWidth,
    double? serialFontWeight,
    double? emptyIconSize,
    double? emptyIconOpacity,
    EdgeInsets? emptySpacing,
    EdgeInsets? paginationPadding,
    Color? paginationBg,
    BorderRadius? dialogRadius,
    EdgeInsets? dialogPadding,
    double? dialogMaxWidth,
    EdgeInsets? dialogFieldSpacing,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? buttonShadow,
    List<BoxShadow>? badgeShadow,
  }) {
    return AppPageTheme(
      searchBarPadding: searchBarPadding ?? this.searchBarPadding,
      searchBarRadius: searchBarRadius ?? this.searchBarRadius,
      searchBarElevation: searchBarElevation ?? this.searchBarElevation,
      searchBarFillColor: searchBarFillColor ?? this.searchBarFillColor,
      searchFieldPadding: searchFieldPadding ?? this.searchFieldPadding,
      cardElevation: cardElevation ?? this.cardElevation,
      cardRadius: cardRadius ?? this.cardRadius,
      cardPadding: cardPadding ?? this.cardPadding,
      cardMargin: cardMargin ?? this.cardMargin,
      tableHeaderPadding: tableHeaderPadding ?? this.tableHeaderPadding,
      tableRowPadding: tableRowPadding ?? this.tableRowPadding,
      tableHeaderFontWeight: tableHeaderFontWeight ?? this.tableHeaderFontWeight,
      tableRowFontWeight: tableRowFontWeight ?? this.tableRowFontWeight,
      tableHeaderBg: tableHeaderBg ?? this.tableHeaderBg,
      tableEvenRowBg: tableEvenRowBg ?? this.tableEvenRowBg,
      tableOddRowBg: tableOddRowBg ?? this.tableOddRowBg,
      tableBorderColor: tableBorderColor ?? this.tableBorderColor,
      tableBorderOpacity: tableBorderOpacity ?? this.tableBorderOpacity,
      buttonPadding: buttonPadding ?? this.buttonPadding,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      buttonElevation: buttonElevation ?? this.buttonElevation,
      iconButtonPadding: iconButtonPadding ?? this.iconButtonPadding,
      iconButtonRadius: iconButtonRadius ?? this.iconButtonRadius,
      iconButtonSize: iconButtonSize ?? this.iconButtonSize,
      badgePadding: badgePadding ?? this.badgePadding,
      badgeRadius: badgeRadius ?? this.badgeRadius,
      badgeWidth: badgeWidth ?? this.badgeWidth,
      badgeIconSize: badgeIconSize ?? this.badgeIconSize,
      badgeFontWeight: badgeFontWeight ?? this.badgeFontWeight,
      badgeLetterSpacing: badgeLetterSpacing ?? this.badgeLetterSpacing,
      serialPadding: serialPadding ?? this.serialPadding,
      serialRadius: serialRadius ?? this.serialRadius,
      serialWidth: serialWidth ?? this.serialWidth,
      serialFontWeight: serialFontWeight ?? this.serialFontWeight,
      emptyIconSize: emptyIconSize ?? this.emptyIconSize,
      emptyIconOpacity: emptyIconOpacity ?? this.emptyIconOpacity,
      emptySpacing: emptySpacing ?? this.emptySpacing,
      paginationPadding: paginationPadding ?? this.paginationPadding,
      paginationBg: paginationBg ?? this.paginationBg,
      dialogRadius: dialogRadius ?? this.dialogRadius,
      dialogPadding: dialogPadding ?? this.dialogPadding,
      dialogMaxWidth: dialogMaxWidth ?? this.dialogMaxWidth,
      dialogFieldSpacing: dialogFieldSpacing ?? this.dialogFieldSpacing,
      cardShadow: cardShadow ?? this.cardShadow,
      buttonShadow: buttonShadow ?? this.buttonShadow,
      badgeShadow: badgeShadow ?? this.badgeShadow,
    );
  }

  @override
  AppPageTheme lerp(ThemeExtension<AppPageTheme>? other, double t) {
    if (other is! AppPageTheme) return this;
    return AppPageTheme(
      searchBarPadding: EdgeInsets.lerp(searchBarPadding, other.searchBarPadding, t) ?? searchBarPadding,
      searchBarRadius: BorderRadius.lerp(searchBarRadius, other.searchBarRadius, t) ?? searchBarRadius,
      searchBarElevation: (searchBarElevation * (1 - t) + other.searchBarElevation * t),
      searchBarFillColor: Color.lerp(searchBarFillColor, other.searchBarFillColor, t) ?? searchBarFillColor,
      searchFieldPadding: EdgeInsets.lerp(searchFieldPadding, other.searchFieldPadding, t) ?? searchFieldPadding,
      cardElevation: (cardElevation * (1 - t) + other.cardElevation * t),
      cardRadius: BorderRadius.lerp(cardRadius, other.cardRadius, t) ?? cardRadius,
      cardPadding: EdgeInsets.lerp(cardPadding, other.cardPadding, t) ?? cardPadding,
      cardMargin: EdgeInsets.lerp(cardMargin, other.cardMargin, t) ?? cardMargin,
      tableHeaderPadding: EdgeInsets.lerp(tableHeaderPadding, other.tableHeaderPadding, t) ?? tableHeaderPadding,
      tableRowPadding: EdgeInsets.lerp(tableRowPadding, other.tableRowPadding, t) ?? tableRowPadding,
      tableHeaderFontWeight: (tableHeaderFontWeight * (1 - t) + other.tableHeaderFontWeight * t),
      tableRowFontWeight: (tableRowFontWeight * (1 - t) + other.tableRowFontWeight * t),
      tableHeaderBg: Color.lerp(tableHeaderBg, other.tableHeaderBg, t) ?? tableHeaderBg,
      tableEvenRowBg: Color.lerp(tableEvenRowBg, other.tableEvenRowBg, t) ?? tableEvenRowBg,
      tableOddRowBg: Color.lerp(tableOddRowBg, other.tableOddRowBg, t) ?? tableOddRowBg,
      tableBorderColor: Color.lerp(tableBorderColor, other.tableBorderColor, t) ?? tableBorderColor,
      tableBorderOpacity: (tableBorderOpacity * (1 - t) + other.tableBorderOpacity * t),
      buttonPadding: EdgeInsets.lerp(buttonPadding, other.buttonPadding, t) ?? buttonPadding,
      buttonRadius: BorderRadius.lerp(buttonRadius, other.buttonRadius, t) ?? buttonRadius,
      buttonElevation: (buttonElevation * (1 - t) + other.buttonElevation * t),
      iconButtonPadding: EdgeInsets.lerp(iconButtonPadding, other.iconButtonPadding, t) ?? iconButtonPadding,
      iconButtonRadius: BorderRadius.lerp(iconButtonRadius, other.iconButtonRadius, t) ?? iconButtonRadius,
      iconButtonSize: (iconButtonSize * (1 - t) + other.iconButtonSize * t),
      badgePadding: EdgeInsets.lerp(badgePadding, other.badgePadding, t) ?? badgePadding,
      badgeRadius: BorderRadius.lerp(badgeRadius, other.badgeRadius, t) ?? badgeRadius,
      badgeWidth: (badgeWidth * (1 - t) + other.badgeWidth * t),
      badgeIconSize: (badgeIconSize * (1 - t) + other.badgeIconSize * t),
      badgeFontWeight: (badgeFontWeight * (1 - t) + other.badgeFontWeight * t),
      badgeLetterSpacing: (badgeLetterSpacing * (1 - t) + other.badgeLetterSpacing * t),
      serialPadding: EdgeInsets.lerp(serialPadding, other.serialPadding, t) ?? serialPadding,
      serialRadius: BorderRadius.lerp(serialRadius, other.serialRadius, t) ?? serialRadius,
      serialWidth: (serialWidth * (1 - t) + other.serialWidth * t),
      serialFontWeight: (serialFontWeight * (1 - t) + other.serialFontWeight * t),
      emptyIconSize: (emptyIconSize * (1 - t) + other.emptyIconSize * t),
      emptyIconOpacity: (emptyIconOpacity * (1 - t) + other.emptyIconOpacity * t),
      emptySpacing: EdgeInsets.lerp(emptySpacing, other.emptySpacing, t) ?? emptySpacing,
      paginationPadding: EdgeInsets.lerp(paginationPadding, other.paginationPadding, t) ?? paginationPadding,
      paginationBg: Color.lerp(paginationBg, other.paginationBg, t) ?? paginationBg,
      dialogRadius: BorderRadius.lerp(dialogRadius, other.dialogRadius, t) ?? dialogRadius,
      dialogPadding: EdgeInsets.lerp(dialogPadding, other.dialogPadding, t) ?? dialogPadding,
      dialogMaxWidth: (dialogMaxWidth * (1 - t) + other.dialogMaxWidth * t),
      dialogFieldSpacing: EdgeInsets.lerp(dialogFieldSpacing, other.dialogFieldSpacing, t) ?? dialogFieldSpacing,
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
      buttonShadow: t < 0.5 ? buttonShadow : other.buttonShadow,
      badgeShadow: t < 0.5 ? badgeShadow : other.badgeShadow,
    );
  }
}

// Modern UI colors extension (unchanged)
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFFFFFBFF),
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 24),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), 
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[
      const AppRoleColors(
        managerBg: Color(0xFFDCFCE7),
        managerText: Color(0xFF166534),
        salesPersonBg: Color(0xFFDBEAFE),
        salesPersonText: Color(0xFF1E40AF),
        fitterBg: Color(0xFFE0E7FF),
        fitterText: Color(0xFF3730A3),
        badgeRadius: BorderRadius.all(Radius.circular(20)),
      ),
      const ModernUIColors(
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
      AppPageTheme(
        cardShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        badgeShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
        tableHeaderBg: Color(0xFF2563EB).withOpacity(0.08),
        tableEvenRowBg: Color(0xFFFFFFFF),
        tableOddRowBg: Color(0xFFF6F8FA),
        paginationBg: Color(0xFFFFFBFF).withOpacity(0.5),
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFF1A1D23),
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 24),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4F83FF), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: const Color(0xFF4F83FF),
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[
      const AppRoleColors(
        managerBg: Color(0xFF1F4A2C),
        managerText: Color(0xFF7EE3A3),
        salesPersonBg: Color(0xFF1E3A8A),
        salesPersonText: Color(0xFF93C5FD),
        fitterBg: Color(0xFF312E81),
        fitterText: Color(0xFFA5B4FC),
        badgeRadius: BorderRadius.all(Radius.circular(20)),
      ),
      const ModernUIColors(
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
      AppPageTheme(
        cardShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        badgeShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
        tableHeaderBg: Color(0xFF4F83FF).withOpacity(0.08),
        tableEvenRowBg: Color(0xFF1A1D23),
        tableOddRowBg: Color(0xFF23272F),
        paginationBg: Color(0xFF1A1D23).withOpacity(0.5),
      ),
    ],
  );
}