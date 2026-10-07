import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Deep slate for titles that sit on white cards.
const kNavy = Color(0xFF1E293B);
const kAccent = Color(0xFF2563EB);
const kCopper = Color(0xFF2563EB);
const kInk = Color(0xFF0F172A);
const kMuted = Color(0xFF64748B);
const kGood = Color(0xFF15803D);
const kWarn = Color(0xFFD97706);
const kBad = Color(0xFFDC2626);
const kInfo = Color(0xFF2563EB);
const kTeal = Color(0xFF0F766E);
const kLine = Color(0xFFE2E8F0);
const kSoft = Color(0xFFEFF6FF);
const kBg = Color(0xFFF8FAFC);

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.ink,
    required this.canvasInk,
    required this.muted,
    required this.canvas,
    required this.card,
    required this.line,
    required this.soft,
    required this.accent,
    required this.sidebar,
    required this.sidebarMuted,
    required this.onSidebar,
  });

  final Color ink;
  final Color canvasInk;
  final Color muted;
  final Color canvas;
  final Color card;
  final Color line;
  final Color soft;
  final Color accent;
  final Color sidebar;
  final Color sidebarMuted;
  final Color onSidebar;

  static const light = AppPalette(
    ink: Color(0xFF0F172A),
    canvasInk: Color(0xFF0F172A),
    muted: Color(0xFF64748B),
    canvas: Color(0xFFF8FAFC),
    card: Color(0xFFFFFFFF),
    line: Color(0xFFE2E8F0),
    soft: Color(0xFFEFF6FF),
    accent: Color(0xFF2563EB),
    sidebar: Color(0xFF0F172A),
    sidebarMuted: Color(0xFF94A3B8),
    onSidebar: Color(0xFFF8FAFC),
  );

  static const dark = AppPalette(
    ink: Color(0xFF0F172A),
    canvasInk: Color(0xFFF8FAFC),
    muted: Color(0xFF94A3B8),
    canvas: Color(0xFF0B1220),
    card: Color(0xFFFFFFFF),
    line: Color(0xFFE2E8F0),
    soft: Color(0xFFEFF6FF),
    accent: Color(0xFF3B82F6),
    sidebar: Color(0xFF020617),
    sidebarMuted: Color(0xFF94A3B8),
    onSidebar: Color(0xFFF8FAFC),
  );

  @override
  AppPalette copyWith({
    Color? ink,
    Color? canvasInk,
    Color? muted,
    Color? canvas,
    Color? card,
    Color? line,
    Color? soft,
    Color? accent,
    Color? sidebar,
    Color? sidebarMuted,
    Color? onSidebar,
  }) {
    return AppPalette(
      ink: ink ?? this.ink,
      canvasInk: canvasInk ?? this.canvasInk,
      muted: muted ?? this.muted,
      canvas: canvas ?? this.canvas,
      card: card ?? this.card,
      line: line ?? this.line,
      soft: soft ?? this.soft,
      accent: accent ?? this.accent,
      sidebar: sidebar ?? this.sidebar,
      sidebarMuted: sidebarMuted ?? this.sidebarMuted,
      onSidebar: onSidebar ?? this.onSidebar,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      ink: Color.lerp(ink, other.ink, t)!,
      canvasInk: Color.lerp(canvasInk, other.canvasInk, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      card: Color.lerp(card, other.card, t)!,
      line: Color.lerp(line, other.line, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      sidebarMuted: Color.lerp(sidebarMuted, other.sidebarMuted, t)!,
      onSidebar: Color.lerp(onSidebar, other.onSidebar, t)!,
    );
  }
}

extension AppPaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

class ThemeController extends ChangeNotifier {
  bool isDark = false;

  AppPalette get palette => isDark ? AppPalette.dark : AppPalette.light;

  void toggle() {
    isDark = !isDark;
    notifyListeners();
  }
}

class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({required ThemeController controller, required super.child, super.key}) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope missing');
    return scope!.notifier!;
  }
}

bool _brandFonts() {
  final name = WidgetsBinding.instance.runtimeType.toString();
  return !name.contains('Test');
}

TextStyle figureStyle(Color color, {double size = 22, FontWeight weight = FontWeight.w700}) {
  final style = TextStyle(
    color: color,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: -0.4,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  if (!_brandFonts()) return style;
  return GoogleFonts.jetBrainsMono(textStyle: style);
}

ThemeData buildAppTheme([AppPalette palette = AppPalette.light]) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: palette.accent,
      brightness: Brightness.light,
      primary: palette.accent,
      onPrimary: Colors.white,
      secondary: palette.accent,
      surface: palette.card,
    ),
    scaffoldBackgroundColor: palette.canvas,
    extensions: [palette],
    appBarTheme: AppBarTheme(
      backgroundColor: palette.canvasInk == palette.ink ? Colors.white : palette.sidebar,
      foregroundColor: palette.canvasInk,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: palette.canvasInk == palette.ink ? Colors.white : palette.sidebar,
      centerTitle: false,
      titleTextStyle: TextStyle(color: palette.canvasInk, fontSize: 18, fontWeight: FontWeight.w800),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: palette.sidebar,
      selectedIconTheme: const IconThemeData(color: Colors.white),
      unselectedIconTheme: IconThemeData(color: palette.sidebarMuted),
      indicatorColor: palette.accent,
    ),
    cardTheme: CardTheme(
      color: palette.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: palette.line),
      ),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: palette.accent,
      unselectedLabelColor: palette.muted,
      indicatorColor: palette.accent,
      dividerColor: palette.line,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.card,
      selectedColor: palette.soft,
      side: BorderSide(color: palette.line),
      labelStyle: TextStyle(color: palette.ink, fontSize: 13, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.card,
      border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: palette.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: palette.accent, width: 1.4),
      ),
      isDense: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.accent,
        side: BorderSide(color: palette.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.accent,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: palette.accent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerColor: palette.line,
    dialogTheme: const DialogTheme(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
    ),
    listTileTheme: ListTileThemeData(iconColor: palette.accent, textColor: palette.ink),
    splashFactory: InkSparkle.splashFactory,
  );
  if (!_brandFonts()) return base;
  final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);
  return base.copyWith(
    textTheme: text,
    primaryTextTheme: GoogleFonts.plusJakartaSansTextTheme(base.primaryTextTheme),
    appBarTheme: base.appBarTheme.copyWith(
      titleTextStyle: GoogleFonts.plusJakartaSans(textStyle: base.appBarTheme.titleTextStyle),
    ),
  );
}
