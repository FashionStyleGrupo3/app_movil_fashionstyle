import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';

/// Diálogo interactivo para recortar y ajustar imágenes con encuadre cuadrado 1:1.
///
/// Implementado 100% en Flutter nativo (InteractiveViewer, RepaintBoundary,
/// dart:ui toImage y path_provider), sin librerías externas nativas de recorte.
class ImageCropEditorDialog extends StatefulWidget {
  final Uint8List imageBytes;
  final double aspectRatio;
  final String title;

  const ImageCropEditorDialog({
    super.key,
    required this.imageBytes,
    this.aspectRatio = 1.0,
    this.title = 'Ajustar imagen al recuadro',
  });

  /// Muestra el modal de recorte y retorna el [File] con la imagen recortada
  /// o `null` si el usuario canceló la acción.
  static Future<File?> show(
    BuildContext context, {
    required Uint8List imageBytes,
    double aspectRatio = 1.0,
    String title = 'Ajustar imagen al recuadro',
  }) {
    return showDialog<File>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (ctx) => ImageCropEditorDialog(
        imageBytes: imageBytes,
        aspectRatio: aspectRatio,
        title: title,
      ),
    );
  }

  @override
  State<ImageCropEditorDialog> createState() => _ImageCropEditorDialogState();
}

class _ImageCropEditorDialogState extends State<ImageCropEditorDialog> {
  final GlobalKey _cropBoundaryKey = GlobalKey();
  final TransformationController _transformationController = TransformationController();

  double _currentScale = 1.0;
  int _quarterTurns = 0;
  bool _procesando = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _onSliderChanged(double newScale, double cropSize) {
    setState(() {
      _currentScale = newScale;
      // Aplica zoom centrado en el recuadro
      final double translationOffset = (cropSize * (1.0 - newScale)) / 2.0;
      final matrix = Matrix4.identity()
        ..translate(translationOffset, translationOffset)
        ..scale(newScale, newScale);
      _transformationController.value = matrix;
    });
  }

  void _rotar() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
    });
  }

  void _restablecer() {
    setState(() {
      _quarterTurns = 0;
      _currentScale = 1.0;
      _transformationController.value = Matrix4.identity();
    });
  }

  Future<void> _guardarYConfirmar() async {
    if (_procesando) return;
    setState(() => _procesando = true);

    try {
      final boundary = _cropBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) Navigator.of(context).pop(null);
        return;
      }

      // Render a alta resolución (pixelRatio 2.0)
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (mounted) Navigator.of(context).pop(null);
        return;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final fileName = 'crop_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes, flush: true);

      if (mounted) {
        Navigator.of(context).pop(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al recortar imagen: $e'),
            backgroundColor: FashionColors.statusDanger,
          ),
        );
        setState(() => _procesando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double cropSize = math.min(screenSize.width - 48, 300.0);

    return Dialog(
      backgroundColor: const Color(0xFF141414),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF2E2E2E), width: 1),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. CABECERA MODAL
              Row(
                children: [
                  const Icon(Icons.crop_rounded, color: Color(0xFFB85338), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: _procesando ? null : () => Navigator.of(context).pop(null),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. RECUADRO DE RECORTE 1:1 CON MÁSCARA Y GUÍAS 3×3
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: cropSize,
                  height: cropSize,
                  child: Stack(
                    children: [
                      // Fondo del recuadro
                      Positioned.fill(
                        child: Container(color: Colors.black),
                      ),

                      // Vista interactiva capturable
                      ClipRect(
                        child: RepaintBoundary(
                          key: _cropBoundaryKey,
                          child: SizedBox(
                            width: cropSize,
                            height: cropSize,
                            child: InteractiveViewer(
                              transformationController: _transformationController,
                              minScale: 1.0,
                              maxScale: 4.0,
                              panEnabled: true,
                              scaleEnabled: true,
                              boundaryMargin: const EdgeInsets.all(double.infinity),
                              onInteractionUpdate: (details) {
                                final scale = _transformationController.value.getMaxScaleOnAxis().clamp(1.0, 4.0);
                                if ((scale - _currentScale).abs() > 0.05) {
                                  setState(() => _currentScale = scale);
                                }
                              },
                              child: Center(
                                child: RotatedBox(
                                  quarterTurns: _quarterTurns,
                                  child: Image.memory(
                                    widget.imageBytes,
                                    fit: BoxFit.cover,
                                    width: cropSize,
                                    height: cropSize,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Guías 3×3 y borde terracota de 1.5px (ignoran toques para permitir pan/zoom)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _CropGridPainter(
                              borderColor: const Color(0xFFB85338),
                              gridColor: Colors.white.withValues(alpha: 0.35),
                              borderWidth: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 3. BARRA DE HERRAMIENTAS: ROTAR Y RESTABLECER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    onPressed: _procesando ? null : _restablecer,
                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                    label: Text(
                      'Restablecer',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF383838)),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _procesando ? null : _rotar,
                    icon: const Icon(Icons.rotate_90_degrees_cw_rounded, size: 15, color: Color(0xFFB85338)),
                    label: Text(
                      'Rotar 90°',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // 4. CONTROL DESLIZANTE DE ZOOM (1.0x - 4.0x)
              Row(
                children: [
                  const Icon(Icons.zoom_out, color: Colors.white54, size: 16),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFB85338),
                        inactiveTrackColor: const Color(0xFF333333),
                        thumbColor: const Color(0xFFB85338),
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      ),
                      child: Slider(
                        value: _currentScale,
                        min: 1.0,
                        max: 4.0,
                        onChanged: _procesando ? null : (val) => _onSliderChanged(val, cropSize),
                      ),
                    ),
                  ),
                  const Icon(Icons.zoom_in, color: Colors.white54, size: 16),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${_currentScale.toStringAsFixed(1)}x',
                      textAlign: TextAlign.end,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 5. BOTONES DE ACCIÓN
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Color(0xFF3A3A3A)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _procesando ? null : () => Navigator.of(context).pop(null),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB85338),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _procesando ? null : _guardarYConfirmar,
                      child: _procesando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Ajustar y usar',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dibuja el marco de recorte con contorno de 1.5px y retícula 3×3 de regla de tercios.
class _CropGridPainter extends CustomPainter {
  final Color borderColor;
  final Color gridColor;
  final double borderWidth;

  _CropGridPainter({
    required this.borderColor,
    required this.gridColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Contorno exterior
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);

    // Retícula 3×3
    final stepX = size.width / 3.0;
    final stepY = size.height / 3.0;

    // Líneas verticales
    canvas.drawLine(Offset(stepX, 0), Offset(stepX, size.height), gridPaint);
    canvas.drawLine(Offset(stepX * 2, 0), Offset(stepX * 2, size.height), gridPaint);

    // Líneas horizontales
    canvas.drawLine(Offset(0, stepY), Offset(size.width, stepY), gridPaint);
    canvas.drawLine(Offset(0, stepY * 2), Offset(size.width, stepY * 2), gridPaint);
  }

  @override
  bool shouldRepaint(covariant _CropGridPainter oldDelegate) => false;
}
