// @source-mirror: src/views/admin/VistaPedidosyFacturas.vue, src/components/pedidos/ModalGestionDespacho.vue, src/components/facturas/ModalCrearFactura.vue, src/components/facturas/ModalCargaMasivaFacturas.vue, src/views/admin/VistaProduccion.vue, src/components/produccion/CalculadoraProduccion.vue, src/components/produccion/GestorOrdenesProduccion.vue
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/data/services/invoice_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

// Modal Carga Masiva de Facturas
class ModalCargaMasivaFacturasSheet extends StatefulWidget {
  final VoidCallback onCompletada;

  const ModalCargaMasivaFacturasSheet({super.key, required this.onCompletada});

  @override
  State<ModalCargaMasivaFacturasSheet> createState() => _ModalCargaMasivaFacturasSheetState();
}

class _ModalCargaMasivaFacturasSheetState extends State<ModalCargaMasivaFacturasSheet> {
  String? _rutaArchivo;
  String? _nombreArchivo;
  bool _subiendo = false;
  double _progreso = 0;

  Future<void> _seleccionarArchivo() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
    );
    if (res != null && res.files.single.path != null) {
      setState(() {
        _rutaArchivo = res.files.single.path;
        _nombreArchivo = res.files.single.name;
      });
    }
  }

  Future<void> _subir() async {
    if (_rutaArchivo == null) return;
    setState(() {
      _subiendo = true;
      _progreso = 0.1;
    });

    try {
      await InvoiceService.instance.cargarFacturasMasivo(
        filePath: _rutaArchivo!,
        fileName: _nombreArchivo ?? 'facturas.csv',
        onSendProgress: (sent, total) {
          if (total > 0 && mounted) {
            setState(() => _progreso = sent / total);
          }
        },
      );
      widget.onCompletada();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Carga masiva completada exitosamente')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No se pudo procesar el archivo de facturas.')),
            backgroundColor: FashionColors.peligro,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: FashionColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: FashionColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Carga Masiva de Facturas',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16, color: FashionColors.inkPrimary),
              ),
              TextButton.icon(
                icon: const Icon(Icons.download, size: 16, color: FashionColors.inkPrimary),
                label: Text('Plantilla CSV', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: FashionColors.inkPrimary)),
                onPressed: () => Share.share(InvoiceService.plantillaCsvContenido, subject: 'Plantilla_Facturas.csv'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: FashionColors.borderSubtle),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _subiendo ? null : _seleccionarArchivo,
            icon: const Icon(Icons.attach_file, color: FashionColors.inkPrimary),
            label: Text(_nombreArchivo ?? 'Seleccionar archivo (.csv / .xlsx)', style: GoogleFonts.plusJakartaSans(color: FashionColors.inkPrimary)),
          ),
          if (_subiendo) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _progreso, color: FashionColors.brandAccent),
          ],
          const SizedBox(height: 18),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FashionColors.brandAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _subiendo || _rutaArchivo == null ? null : _subir,
            child: Text('Subir y Procesar', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. PRODUCCIÓN Y COSTOS (VistaProduccion.vue)
// ============================================================================
