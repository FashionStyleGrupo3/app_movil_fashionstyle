// @source-mirror: src/views/admin/VistaPedidosyFacturas.vue, src/components/pedidos/ModalGestionDespacho.vue, src/components/facturas/ModalCrearFactura.vue, src/components/facturas/ModalCargaMasivaFacturas.vue, src/views/admin/VistaProduccion.vue, src/components/produccion/CalculadoraProduccion.vue, src/components/produccion/GestorOrdenesProduccion.vue
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/data/services/invoice_service.dart';

// Modal Crear Factura
class ModalCrearFacturaSheet extends StatefulWidget {
  final VoidCallback onCreada;

  const ModalCrearFacturaSheet({super.key, required this.onCreada});

  @override
  State<ModalCrearFacturaSheet> createState() => _ModalCrearFacturaSheetState();
}

class _ModalCrearFacturaSheetState extends State<ModalCrearFacturaSheet> {
  String _origen = 'pedido';
  final TextEditingController _refIdCtrl = TextEditingController();
  final TextEditingController _metodoCtrl = TextEditingController(text: 'WOMPI');
  bool _creando = false;

  Future<void> _crear() async {
    final id = int.tryParse(_refIdCtrl.text.trim()) ?? 0;
    if (id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa un ID válido de pedido o venta')));
      return;
    }

    setState(() => _creando = true);
    try {
      await InvoiceService.instance.crearFactura(
        origen: _origen,
        referenciaId: id,
        metodoPago: _metodoCtrl.text.trim(),
      );
      widget.onCreada();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No se pudo crear la factura. Verifica los datos ingresados.')),
            backgroundColor: FashionColors.peligro,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _creando = false);
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
          Text(
            'Emitir Factura Manual',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 17, color: FashionColors.inkPrimary),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _origen,
            decoration: InputDecoration(
              labelText: 'Origen de operación',
              filled: true,
              fillColor: FashionColors.surfaceMuted,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            items: const [
              DropdownMenuItem(value: 'pedido', child: Text('Pedido Online')),
              DropdownMenuItem(value: 'venta', child: Text('Venta POS Mostrador')),
            ],
            onChanged: (v) => setState(() => _origen = v ?? 'pedido'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _refIdCtrl,
            keyboardType: TextInputType.number,
            style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: 'ID de la operación *',
              filled: true,
              fillColor: FashionColors.surfaceMuted,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _metodoCtrl,
            decoration: InputDecoration(
              labelText: 'Método de pago',
              filled: true,
              fillColor: FashionColors.surfaceMuted,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: FashionColors.brandAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _creando ? null : _crear,
            child: _creando
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Emitir Factura', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
