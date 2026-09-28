import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.forest,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.forest,
    onPrimary: Colors.white,
    secondary: AppColors.lime,
    onSecondary: AppColors.ink,
    surface: AppColors.cream,
    onSurface: AppColors.ink,
    error: AppColors.danger,
  );

  const cupertino = CupertinoPageTransitionsBuilder();

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.cream,
    fontFamily: AppText.body,
    splashFactory: InkRipple.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: cupertino,
        TargetPlatform.iOS: cupertino,
        TargetPlatform.linux: cupertino,
        TargetPlatform.macOS: cupertino,
        TargetPlatform.windows: cupertino,
      },
    ),
  );
}
