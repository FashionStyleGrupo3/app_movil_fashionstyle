// @source-mirror: tailwind.config.js, src/style.css
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de color oficial FashionStyle Mobile "Neo-Atelier Mineral & Terracotta".
///
/// Combina un fondo mineral ultra-limpio con la calidez sartorial del Terracotta Couture (#B83A24),
/// acentos jade de taller (#115E59) y negros entintados (#14161F).
class FashionColors {
  // --- PALETA PRIMARIA MÓVIL (NEO-ATELIER MINERAL & TERRACOTTA) ---
  static const Color canvasBackground = Color(0xFFF6F7F9);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEBEEF3);
  static const Color inkPrimary = Color(0xFF14161F);
  static const Color inkSecondary = Color(0xFF525866);
  static const Color brandAccent = Color(0xFFB83A24); // Terracotta Couture
  static const Color atelierJade = Color(0xFF115E59); // Verde Jade de Taller
  static const Color editorialOchre = Color(0xFF9A6700);
  static const Color editorialGoldDark = Color(0xFFF59F00);
  static const Color borderSubtle = Color(0xFFDFE3EC);
  static const Color statusSuccess = Color(0xFF157347);
  static const Color statusWarning = Color(0xFF9A6700);
  static const Color statusDanger = Color(0xFFC92A2A);

  // --- ALIASES Y CONSTANTES LEGACY (COMPATIBILIDAD 100% RETROACTIVA) ---
  static const Color negro = inkPrimary;
  static const Color texto = inkPrimary;
  static const Color gris = inkSecondary;
  static const Color crema = canvasBackground;
  static const Color arena = surfaceMuted;
  static const Color arenaSuave = surfaceMuted;
  static const Color arenaOscura = borderSubtle;
  static const Color pizarra = inkSecondary;
  static const Color borde = borderSubtle;
  static const Color rojo = statusDanger;
  static const Color rosaCorporativo = brandAccent;
  static const Color blanco = surfaceCard;
  static const Color verdeExito = statusSuccess;

  static const Color fondoClaro = canvasBackground;
  static const Color textoOscuro = inkPrimary;
  static const Color textoMuted = inkSecondary;
  static const Color grisBorde = borderSubtle;
  static const Color negroElegante = inkPrimary;
  static const Color peligro = statusDanger;
  static const Color aviso = statusWarning;
  static const Color rosaSuave = surfaceMuted;
  static const Color rosaOscuro = brandAccent;
  static const Color exito = statusSuccess;
  static const Color cremaSuave = surfaceMuted;
  static const Color azulInfo = atelierJade;
}

class FashionTheme {
  /// Estilo monoespaciado técnico para precios monetarios en COP, códigos y SKU.
  static TextStyle priceTextStyle({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w700,
    Color color = FashionColors.inkPrimary,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      decoration: decoration,
      fontFeatures: const [FontFeature.tabularFigures()],
      letterSpacing: -0.3,
    );
  }

  /// Estilo numérico para métricas analíticas de KPIs y contadores.
  static TextStyle monoMetricStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w600,
    Color color = FashionColors.inkPrimary,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
      letterSpacing: -0.5,
    );
  }

  static ThemeData get lightTheme {
    // Tríada tipográfica: Space Grotesk (Titulares) + Plus Jakarta Sans (Cuerpo) + JetBrains Mono (Precios)
    final textTheme = TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(
        color: FashionColors.inkPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        color: FashionColors.inkPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        color: FashionColors.inkPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      headlineLarge: GoogleFonts.spaceGrotesk(
        color: FashionColors.inkPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        color: FashionColors.inkPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        color: FashionColors.inkPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        color: FashionColors.inkPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        color: FashionColors.inkPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        color: FashionColors.inkSecondary,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        color: FashionColors.inkPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        color: FashionColors.inkPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        color: FashionColors.inkSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        color: FashionColors.inkPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        color: FashionColors.inkSecondary,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        color: FashionColors.inkSecondary,
        fontWeight: FontWeight.w500,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: FashionColors.brandAccent,
      scaffoldBackgroundColor: FashionColors.canvasBackground,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: FashionColors.brandAccent,
        onPrimary: FashionColors.surfaceCard,
        secondary: FashionColors.inkPrimary,
        onSecondary: FashionColors.surfaceCard,
        tertiary: FashionColors.atelierJade,
        onTertiary: FashionColors.surfaceCard,
        error: FashionColors.statusDanger,
        onError: FashionColors.surfaceCard,
        surface: FashionColors.surfaceCard,
        onSurface: FashionColors.inkPrimary,
        surfaceContainerHighest: FashionColors.surfaceMuted,
        outline: FashionColors.borderSubtle,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: FashionColors.canvasBackground,
        foregroundColor: FashionColors.inkPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: FashionColors.inkPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: FashionColors.inkPrimary),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: FashionColors.surfaceCard,
        modalBackgroundColor: FashionColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: FashionColors.borderSubtle,
        dragHandleSize: Size(44, 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      cardTheme: CardThemeData(
        color: FashionColors.surfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: FashionColors.borderSubtle, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FashionColors.brandAccent,
          foregroundColor: FashionColors.surfaceCard,
          disabledBackgroundColor: FashionColors.surfaceMuted,
          disabledForegroundColor: FashionColors.inkSecondary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FashionColors.brandAccent,
          foregroundColor: FashionColors.surfaceCard,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FashionColors.inkPrimary,
          side: const BorderSide(color: FashionColors.borderSubtle, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FashionColors.brandAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FashionColors.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: FashionColors.inkSecondary,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: FashionColors.inkPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FashionColors.borderSubtle, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FashionColors.borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FashionColors.brandAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FashionColors.statusDanger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: FashionColors.statusDanger, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: FashionColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: FashionColors.surfaceCard,
        selectedItemColor: FashionColors.brandAccent,
        unselectedItemColor: FashionColors.inkSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      ),
    );
  }
}
