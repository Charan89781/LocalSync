import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        color: primaryColor,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: primaryColor,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: primaryColor,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: primaryColor,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: primaryColor,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: primaryColor,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: primaryColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: primaryColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: primaryColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: secondaryColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: secondaryColor,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: secondaryColor,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: primaryColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: primaryColor,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: secondaryColor,
      ),
    );
  }

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFD6E8FF),
      onPrimaryContainer: Color(0xFF003063),
      secondary: AppColors.neonCyan,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFCCF6FF),
      onSecondaryContainer: Color(0xFF003640),
      tertiary: AppColors.neonPurple,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFEADDFF),
      onTertiaryContainer: Color(0xFF1D0160),
      error: AppColors.errorRed,
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: Colors.white,
      onSurface: AppColors.textDark,
      surfaceContainerHighest: Color(0xFFE7E0EC),
      onSurfaceVariant: AppColors.textGray,
      outline: Color(0xFFCAC4D0),
      outlineVariant: Color(0xFFECE6F0),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF1C1B1F),
      onInverseSurface: Color(0xFFF4EFF4),
      inversePrimary: Color(0xFFB8C5FF),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(AppColors.textDark, AppColors.textGray),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textDark, size: 24),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
        color: Colors.white,
        shadowColor: AppColors.primaryBlue.withOpacity(0.08),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.grey.shade300;
            }
            return AppColors.primaryBlue;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.grey.shade500;
            }
            return Colors.white;
          }),
          minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 56)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return 0;
            return 4;
          }),
          shadowColor:
              WidgetStatePropertyAll(AppColors.primaryBlue.withOpacity(0.35)),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          overlayColor:
              WidgetStatePropertyAll(Colors.white.withOpacity(0.15)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          animationDuration: const Duration(milliseconds: 200),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor:
              const WidgetStatePropertyAll(AppColors.primaryBlue),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.focused)) {
              return const BorderSide(color: AppColors.primaryBlue, width: 2);
            }
            return const BorderSide(color: AppColors.primaryBlue, width: 1.5);
          }),
          minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 56)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor:
              const WidgetStatePropertyAll(AppColors.primaryBlue),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
        ),
        labelStyle:
            GoogleFonts.inter(color: AppColors.textGray, fontSize: 14),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textLight,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        errorStyle:
            GoogleFonts.inter(color: AppColors.errorRed, fontSize: 12),
        prefixIconColor: AppColors.textGray,
        suffixIconColor: AppColors.textGray,
        floatingLabelStyle:
            const TextStyle(color: AppColors.primaryBlue, fontSize: 13),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedColor: AppColors.primaryBlue.withOpacity(0.12),
        disabledColor: Colors.grey.shade200,
        labelStyle:
            GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryBlue,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        elevation: 0,
        pressElevation: 2,
        checkmarkColor: AppColors.primaryBlue,
        iconTheme: const IconThemeData(size: 18),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        modalBackgroundColor: Colors.white,
        dragHandleColor: Colors.grey.shade300,
        dragHandleSize: const Size(40, 4),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1C1B1F),
        contentTextStyle:
            GoogleFonts.inter(color: Colors.white, fontSize: 14),
        actionTextColor: AppColors.neonCyan,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 24,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.inter(
          color: AppColors.textGray,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textDark,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          color: AppColors.textGray,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        iconColor: AppColors.textGray,
        minLeadingWidth: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 8,
        focusElevation: 12,
        hoverElevation: 10,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        extendedPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        extendedTextStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryBlue;
          }
          return Colors.grey.shade300;
        }),
        trackOutlineColor:
            const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryBlue,
        linearTrackColor: Color(0xFFD6E8FF),
        circularTrackColor: Color(0xFFD6E8FF),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryBlue,
        unselectedLabelColor: AppColors.textGray,
        indicatorColor: AppColors.primaryBlue,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle:
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
      ),
    );
  }

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.neonCyan,
      onPrimary: AppColors.primaryNavy,
      primaryContainer: Color(0xFF004757),
      onPrimaryContainer: Color(0xFF9DECFF),
      secondary: AppColors.primaryBlue,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF003063),
      onSecondaryContainer: Color(0xFFB8C5FF),
      tertiary: AppColors.neonPurple,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFF30006E),
      onTertiaryContainer: Color(0xFFEADDFF),
      error: AppColors.errorRed,
      onError: Colors.white,
      errorContainer: Color(0xFF8C1D18),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: AppColors.secondaryNavy,
      onSurface: Colors.white,
      surfaceContainerHighest: AppColors.surfaceNavy,
      onSurfaceVariant: Color(0xFFCAC4D0),
      outline: Color(0xFF49454F),
      outlineVariant: Color(0xFF1E2732),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Colors.white,
      onInverseSurface: AppColors.textDark,
      inversePrimary: AppColors.primaryBlue,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(Colors.white, const Color(0xFFCAC4D0)),
      scaffoldBackgroundColor: AppColors.primaryNavy,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.secondaryNavy,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: Colors.white.withOpacity(0.08), width: 1),
        ),
        color: AppColors.secondaryNavy,
        shadowColor: Colors.black.withOpacity(0.4),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.surfaceNavy;
            }
            return AppColors.neonCyan;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.white38;
            }
            return AppColors.primaryNavy;
          }),
          minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 56)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return 0;
            return 4;
          }),
          shadowColor:
              WidgetStatePropertyAll(AppColors.neonCyan.withOpacity(0.4)),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          overlayColor: WidgetStatePropertyAll(
              AppColors.primaryNavy.withOpacity(0.1)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceNavy,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: Colors.white.withOpacity(0.08), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              color: Colors.white.withOpacity(0.08), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.neonCyan, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.errorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
            color: const Color(0xFFCAC4D0), fontSize: 14),
        hintStyle: GoogleFonts.inter(
          color: Colors.white38,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        errorStyle:
            GoogleFonts.inter(color: AppColors.errorRed, fontSize: 12),
        prefixIconColor: const Color(0xFFCAC4D0),
        suffixIconColor: const Color(0xFFCAC4D0),
        floatingLabelStyle:
            const TextStyle(color: AppColors.neonCyan, fontSize: 13),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceNavy,
        selectedColor: AppColors.neonCyan.withOpacity(0.2),
        labelStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white70),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.neonCyan,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        elevation: 0,
        checkmarkColor: AppColors.neonCyan,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.secondaryNavy,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        modalBackgroundColor: AppColors.secondaryNavy,
        dragHandleColor: Colors.white30,
        dragHandleSize: const Size(40, 4),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.08),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceNavy,
        contentTextStyle:
            GoogleFonts.inter(color: Colors.white, fontSize: 14),
        actionTextColor: AppColors.neonCyan,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.secondaryNavy,
        surfaceTintColor: Colors.transparent,
        elevation: 24,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: GoogleFonts.inter(
          color: Colors.white60,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        iconColor: Colors.white60,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.neonCyan,
        foregroundColor: AppColors.primaryNavy,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        extendedTextStyle:
            GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: AppColors.neonCyan,
        unselectedLabelColor: Colors.white54,
        indicatorColor: AppColors.neonCyan,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle:
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.neonCyan,
        linearTrackColor: AppColors.neonCyan.withOpacity(0.15),
        circularTrackColor: AppColors.neonCyan.withOpacity(0.15),
      ),
    );
  }
}
