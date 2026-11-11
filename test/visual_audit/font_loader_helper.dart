import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

bool _fontsLoaded = false;

Future<void> loadAppFontsZeroAhem() async {
  if (_fontsLoaded) return;

  // Desactivar descargas HTTP de GoogleFonts durante tests
  GoogleFonts.config.allowRuntimeFetching = false;

  // 1. MaterialIcons
  final materialPath = 'C:/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
  if (File(materialPath).existsSync()) {
    final bytes = File(materialPath).readAsBytesSync();
    final loader = FontLoader('MaterialIcons');
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
  }

  // 2. Space Grotesk
  final sgFiles = [
    'assets/fonts/SpaceGrotesk-Regular.ttf',
    'assets/fonts/SpaceGrotesk-Medium.ttf',
    'assets/fonts/SpaceGrotesk-SemiBold.ttf',
    'assets/fonts/SpaceGrotesk-Bold.ttf',
  ];
  for (final family in ['Space Grotesk', 'SpaceGrotesk', 'Space_Grotesk']) {
    final loader = FontLoader(family);
    for (final p in sgFiles) {
      if (File(p).existsSync()) {
        final b = File(p).readAsBytesSync();
        loader.addFont(Future.value(ByteData.view(b.buffer)));
      }
    }
    await loader.load();
  }

  // 3. Plus Jakarta Sans
  final pjsFiles = [
    'assets/fonts/PlusJakartaSans-Regular.ttf',
    'assets/fonts/PlusJakartaSans-Medium.ttf',
    'assets/fonts/PlusJakartaSans-SemiBold.ttf',
    'assets/fonts/PlusJakartaSans-Bold.ttf',
  ];
  for (final family in ['Plus Jakarta Sans', 'PlusJakartaSans', 'Plus_Jakarta_Sans', 'Roboto', '.AppleSystemUIFont']) {
    final loader = FontLoader(family);
    for (final p in pjsFiles) {
      if (File(p).existsSync()) {
        final b = File(p).readAsBytesSync();
        loader.addFont(Future.value(ByteData.view(b.buffer)));
      }
    }
    await loader.load();
  }

  // 4. JetBrains Mono
  final jbmFiles = [
    'assets/fonts/JetBrainsMono-Regular.ttf',
    'assets/fonts/JetBrainsMono-Medium.ttf',
    'assets/fonts/JetBrainsMono-SemiBold.ttf',
    'assets/fonts/JetBrainsMono-Bold.ttf',
  ];
  for (final family in ['JetBrains Mono', 'JetBrainsMono', 'JetBrains_Mono', 'monospace']) {
    final loader = FontLoader(family);
    for (final p in jbmFiles) {
      if (File(p).existsSync()) {
        final b = File(p).readAsBytesSync();
        loader.addFont(Future.value(ByteData.view(b.buffer)));
      }
    }
    await loader.load();
  }

  _fontsLoaded = true;
}
