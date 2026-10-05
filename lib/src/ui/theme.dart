import 'package:flutter/material.dart';

const kNavy = Color(0xFF1D4E89);
const kCopper = Color(0xFF1D4E89);
const kInk = Color(0xFF0F172A);
const kMuted = Color(0xFF64748B);
const kGood = Color(0xFF157A3A);
const kWarn = Color(0xFFB45309);
const kBad = Color(0xFFB42318);
const kInfo = Color(0xFF0369A1);
const kTeal = Color(0xFF0F766E);
const kLine = Color(0xFFE2E8F0);
const kSoft = Color(0xFFE8F1FB);
const kBg = Color(0xFFF4F7FB);

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kNavy,
      primary: kNavy,
      secondary: kInfo,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: kBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: kInk,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.white,
      centerTitle: false,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Colors.white,
      selectedIconTheme: IconThemeData(color: kNavy),
      unselectedIconTheme: IconThemeData(color: kMuted),
      selectedLabelTextStyle: TextStyle(color: kNavy, fontWeight: FontWeight.w700, fontSize: 13),
      unselectedLabelTextStyle: TextStyle(color: kMuted, fontSize: 13),
      indicatorColor: kSoft,
    ),
    cardTheme: const CardTheme(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
        side: BorderSide(color: kLine),
      ),
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: kNavy,
      unselectedLabelColor: kMuted,
      indicatorColor: kNavy,
      dividerColor: kLine,
      labelStyle: TextStyle(fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: kSoft,
      side: const BorderSide(color: kLine),
      labelStyle: const TextStyle(color: kInk, fontSize: 13),
      secondaryLabelStyle: const TextStyle(color: kNavy, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: kLine),
      ),
      isDense: true,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kNavy,
      foregroundColor: Colors.white,
    ),
    dividerColor: kLine,
    dialogTheme: const DialogTheme(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
    ),
    listTileTheme: const ListTileThemeData(iconColor: kNavy, textColor: kInk),
  );
}
