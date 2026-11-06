// @source-mirror: tailwind.config.js, src/style.css
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FashionColors {
  static const Color negro = Color(0xFF111111);
  static const Color texto = Color(0xFF2B2B2B);
  static const Color gris = Color(0xFF6F6F6F);
  static const Color crema = Color(0xFFF7F4EF);
  static const Color arena = Color(0xFFECE5DA);
  static const Color arenaSuave = Color(0xFFF3EEE6);
  static const Color arenaOscura = Color(0xFFD4C2A8);
  static const Color pizarra = Color(0xFF56657A);
  static const Color borde = Color(0xFFE4DDD2);
  static const Color rojo = Color(0xFFD9434B);
  static const Color rosaCorporativo = Color(0xFF111111); // Alineado con la paleta de lujo neutral de la Web (#111111)
  static const Color blanco = Color(0xFFFFFFFF);
  static const Color verdeExito = Color(0xFF2E7D32);

  // Aliases compatibles con las pantallas
  static const Color fondoClaro = crema;
  static const Color textoOscuro = texto;
  static const Color textoMuted = gris;
  static const Color grisBorde = borde;
  static const Color negroElegante = negro;
  static const Color peligro = rojo;
  static const Color aviso = Color(0xFFE65100);
  static const Color rosaSuave = arenaSuave;
  static const Color rosaOscuro = rosaCorporativo;
  static const Color exito = verdeExito;
  static const Color cremaSuave = arenaSuave;
  static const Color azulInfo = pizarra;
}

class FashionTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme;
    final poppinsTheme = GoogleFonts.poppinsTextTheme(baseTextTheme);
    final montserratTheme = GoogleFonts.montserratTextTheme(baseTextTheme);

    final mergedTextTheme = montserratTheme.copyWith(
      displayLarge: poppinsTheme.displayLarge?.copyWith(
        color: FashionColors.negro,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      displayMedium: poppinsTheme.displayMedium?.copyWith(
        color: FashionColors.negro,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: poppinsTheme.displaySmall?.copyWith(
        color: FashionColors.negro,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: poppinsTheme.headlineLarge?.copyWith(
        color: FashionColors.negro,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: poppinsTheme.headlineMedium?.copyWith(
        color: FashionColors.negro,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: poppinsTheme.headlineSmall?.copyWith(
        color: FashionColors.negro,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: poppinsTheme.titleLarge?.copyWith(
        color: FashionColors.texto,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: poppinsTheme.titleMedium?.copyWith(
        color: FashionColors.texto,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: poppinsTheme.titleSmall?.copyWith(
        color: FashionColors.texto,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: montserratTheme.bodyLarge?.copyWith(
        color: FashionColors.texto,
        fontSize: 16,
      ),
      bodyMedium: montserratTheme.bodyMedium?.copyWith(
        color: FashionColors.texto,
        fontSize: 14,
      ),
      bodySmall: montserratTheme.bodySmall?.copyWith(
        color: FashionColors.gris,
        fontSize: 12,
      ),
      labelLarge: poppinsTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: FashionColors.negro,
      scaffoldBackgroundColor: FashionColors.crema,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: FashionColors.negro,
        onPrimary: FashionColors.blanco,
        secondary: FashionColors.pizarra,
        onSecondary: FashionColors.blanco,
        error: FashionColors.rojo,
        onError: FashionColors.blanco,
        surface: FashionColors.blanco,
        onSurface: FashionColors.texto,
        surfaceContainerHighest: FashionColors.arenaSuave,
        outline: FashionColors.borde,
      ),
      textTheme: mergedTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: FashionColors.crema,
        foregroundColor: FashionColors.negro,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          color: FashionColors.negro,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: FashionColors.negro),
      ),
      cardTheme: CardThemeData(
        color: FashionColors.blanco,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: FashionColors.borde, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FashionColors.negro,
          foregroundColor: FashionColors.blanco,
          disabledBackgroundColor: FashionColors.borde,
          disabledForegroundColor: FashionColors.gris,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FashionColors.negro,
          side: const BorderSide(color: FashionColors.negro, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FashionColors.pizarra,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FashionColors.blanco,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          color: FashionColors.gris,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: FashionColors.texto,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: FashionColors.borde, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: FashionColors.borde, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: FashionColors.negro, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: FashionColors.rojo, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: FashionColors.rojo, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: FashionColors.borde,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: FashionColors.blanco,
        selectedItemColor: FashionColors.negro,
        unselectedItemColor: FashionColors.gris,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      ),
    );
  }
}
