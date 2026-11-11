// @source-mirror: src/views/admin/VistaPedidosyFacturas.vue, src/components/pedidos/ModalGestionDespacho.vue, src/components/facturas/ModalCrearFactura.vue, src/components/facturas/ModalCargaMasivaFacturas.vue, src/views/admin/VistaProduccion.vue, src/components/produccion/CalculadoraProduccion.vue, src/components/produccion/GestorOrdenesProduccion.vue
import 'package:flutter/material.dart';
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
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Emitir Factura Manual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _origen,
            decoration: const InputDecoration(labelText: 'Origen de operación', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'pedido', child: Text('Pedido Online')),
              DropdownMenuItem(value: 'venta', child: Text('Venta POS Mostrador')),
            ],
            onChanged: (v) => setState(() => _origen = v ?? 'pedido'),
          ),
          const SizedBox(height: 10),
          TextField(controller: _refIdCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ID de la operación *', border: OutlineInputBorder())),
          const SizedBox(height: 10),
          TextField(controller: _metodoCtrl, decoration: const InputDecoration(labelText: 'Método de pago', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante, foregroundColor: Colors.white),
            onPressed: _creando ? null : _crear,
            child: _creando ? const CircularProgressIndicator(color: Colors.white) : const Text('Emitir Factura'),
          ),
        ],
      ),
    );
  }
}
