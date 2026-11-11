// @source-mirror: src/views/publico/VistaCarrito.vue, src/views/publico/VistaTerminos.vue
import 'package:flutter/material.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/presentation/layouts/public_shell_layout.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _cargando = true;
  String? _error;
  Map<String, dynamic>? _termino;

  @override
  void initState() {
    super.initState();
    _cargarTerminos();
  }

  Future<void> _cargarTerminos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final response = await ApiClient.instance.dio.get('/terminos-condiciones');
      final data = ApiResponseParser.extractData(response);
      if (mounted) {
        setState(() {
          _termino = data is Map<String, dynamic> ? data : {};
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No fue posible cargar los términos y condiciones desde el servidor.';
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PublicShellLayout(
      child: _cargando
          ? const Center(child: CircularProgressIndicator(color: FashionColors.inkPrimary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: FashionColors.statusDanger),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(color: FashionColors.inkPrimary)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FashionColors.inkPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _cargarTerminos,
                          child: const Text('Reintentar conexión'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 96), // Clearance para Floating Pill Dock
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: FashionColors.surfaceCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: FashionColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _termino?['titulo']?.toString() ?? 'Términos y Condiciones de Uso',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: FashionColors.inkPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Versión ${_termino?['version'] ?? '1.0'}',
                          style: GoogleFonts.jetBrainsMono(fontSize: 12, color: FashionColors.inkSecondary),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: FashionColors.borderSubtle),
                        const SizedBox(height: 16),
                        Text(
                          _termino?['contenido']?.toString() ??
                              'Al acceder a nuestra plataforma y adquirir productos, aceptas nuestros términos de despacho, garantías y tratamiento seguro de datos.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            height: 1.6,
                            color: FashionColors.inkPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
