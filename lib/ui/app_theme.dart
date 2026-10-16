import 'package:flutter/material.dart';
import 'discfit_widgets.dart';

ThemeData discFitTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(seedColor: forest, brightness: brightness);
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  return base.copyWith(
    scaffoldBackgroundColor: dark ? const Color(0xff101b16) : canvas,
    textTheme: base.textTheme.copyWith(
      bodyMedium:
          base.textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.5),
      titleLarge: base.textTheme.titleLarge
          ?.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
        backgroundColor: dark ? const Color(0xff101b16) : canvas,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent),
    cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: scheme.outlineVariant))),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? scheme.surfaceContainerHighest : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant)),
    ),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            minimumSize: const Size(48, 52), shape: shape)),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 50), shape: shape)),
    snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? scheme.inverseSurface : forest,
        contentTextStyle:
            TextStyle(color: dark ? scheme.onInverseSurface : Colors.white),
        shape: shape),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
  );
}
