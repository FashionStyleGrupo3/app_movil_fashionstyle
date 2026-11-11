// @source-mirror: src/router/index.js
import 'package:flutter/material.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class FashionPlaceholderScreen extends StatelessWidget {
  final String title;
  final String path;

  const FashionPlaceholderScreen({
    super.key,
    required this.title,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FashionColors.canvasBackground,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: FashionColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: FashionColors.borderSubtle),
                ),
                child: const Icon(
                  Icons.hourglass_empty_rounded,
                  size: 36,
                  color: FashionColors.brandAccent,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: FashionColors.inkPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: FashionColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  path,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: FashionColors.inkSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Módulo en proceso de integración en el Cockpit Atelier.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: FashionColors.inkSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
