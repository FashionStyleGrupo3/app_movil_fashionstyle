// @source-mirror: src/router/index.js
import 'package:flutter/material.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';

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
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.hourglass_empty_rounded,
                size: 48,
                color: FashionColors.pizarra,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Ruta: $path\nPantalla lista para conectarse en los siguientes pasos.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
