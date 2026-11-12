// @source-mirror: tailwind.config.js, src/style.css
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de color oficial FashionStyle Mobile (Paridad 100% con Frontend Web).
///
/// Colores corporativos oficiales:
/// Negro corporativo (#111111), Fondo crema (#F7F4EF), Arena suave (#F3EEE6),
/// Arena (#ECE5DA), Arena oscura (#D4C2A8), Pizarra (#56657A), Borde (#E4DDD2),
/// Texto principal (#2B2B2B), Gris tenue (#6F6F6F), Rojo (#D9434B), Verde éxito (#2E7D32).
class FashionColors {
  // --- PALETA PRIMARIA MÓVIL (FASHIONSTYLE WEB OFICIAL) ---
  static const Color canvasBackground = Color(0xFFF7F4EF); // #F7F4EF Fondo crema web oficial
  static const Color surfaceCard = Color(0xFFFFFFFF); // #FFFFFF
  static const Color surfaceMuted = Color(0xFFF3EEE6); // #F3EEE6 Arena suave
  static const Color surfacePanel = Color(0xFFECE5DA); // #ECE5DA Arena panel
  static const Color inkPrimary = Color(0xFF111111); // #111111 Negro corporativo
  static const Color inkSecondary = Color(0xFF2B2B2B); // #2B2B2B Texto principal
  static const Color inkMuted = Color(0xFF6F6F6F); // #6F6F6F Gris tenue
  static const Color brandAccent = Color(0xFF111111); // #111111 Primario web oficial
  static const Color brandAccentHover = Color(0xFF333333); // #333333
  static const Color slateAccent = Color(0xFF56657A); // #56657A Pizarra
  static const Color sandDark = Color(0xFFD4C2A8); // #D4C2A8 Arena oscura
  static const Color atelierJade = Color(0xFF56657A); // Alias de compatibilidad con Pizarra #56657A
  static const Color editorialOchre = Color(0xFF9A6700);
  static const Color editorialGoldDark = Color(0xFFF59F00);
  static const Color borderSubtle = Color(0xFFE4DDD2); // #E4DDD2 Borde tienda web
  static const Color borderSoft = Color(0xFFF3EEE6);
  static const Color borderStrong = Color(0xFFD4CBBD);
  static const Color statusSuccess = Color(0xFF2E7D32); // #2E7D32 Verde éxito
  static const Color statusWarning = Color(0xFF9A6700);
  static const Color statusDanger = Color(0xFFD9434B); // #D9434B Rojo tienda web

  // --- ALIASES Y CONSTANTES LEGACY (COMPATIBILIDAD 100% RETROACTIVA) ---
  static const Color negro = inkPrimary;
  static const Color texto = inkSecondary;
  static const Color gris = inkMuted;
  static const Color crema = canvasBackground;
  static const Color arena = surfacePanel;
  static const Color arenaSuave = surfaceMuted;
  static const Color arenaOscura = sandDark;
  static const Color pizarra = slateAccent;
  static const Color borde = borderSubtle;
  static const Color rojo = statusDanger;
  static const Color rosaCorporativo = brandAccent;
  static const Color blanco = surfaceCard;
  static const Color verdeExito = statusSuccess;

  static const Color fondoClaro = canvasBackground;
  static const Color textoOscuro = inkSecondary;
  static const Color textoMuted = inkMuted;
  static const Color grisBorde = borderSubtle;
  static const Color negroElegante = inkPrimary;
  static const Color peligro = statusDanger;
  static const Color aviso = statusWarning;
  static const Color rosaSuave = surfaceMuted;
  static const Color rosaOscuro = brandAccent;
  static const Color exito = statusSuccess;
  static const Color cremaSuave = surfaceMuted;
  static const Color azulInfo = slateAccent;

  // Aliases de diseño unificado
  static const Color backgroundCanvas = canvasBackground;
  static const Color primaryCorporate = inkPrimary;
  static const Color surfaceSecondary = surfaceMuted;
  static const Color bordeClaro = borderSubtle;
  static const Color textoPrincipal = inkSecondary;
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
    // Tipografía oficial Web: Montserrat (Titulares) + Poppins (Cuerpo e Interfaz) + JetBrains Mono (Precios)
    final textTheme = TextTheme(
      displayLarge: GoogleFonts.montserrat(
        color: FashionColors.inkPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.montserrat(
        color: FashionColors.inkPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.montserrat(
        color: FashionColors.inkPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      headlineLarge: GoogleFonts.montserrat(
        color: FashionColors.inkPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.montserrat(
        color: FashionColors.inkPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      headlineSmall: GoogleFonts.montserrat(
        color: FashionColors.inkPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.montserrat(
        color: FashionColors.inkPrimary,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleMedium: GoogleFonts.poppins(
        color: FashionColors.inkPrimary,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: GoogleFonts.poppins(
        color: FashionColors.inkSecondary,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: GoogleFonts.poppins(
        color: FashionColors.inkPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.poppins(
        color: FashionColors.inkPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: GoogleFonts.poppins(
        color: FashionColors.inkSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: GoogleFonts.poppins(
        color: FashionColors.inkPrimary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
      labelMedium: GoogleFonts.poppins(
        color: FashionColors.inkSecondary,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: GoogleFonts.poppins(
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
