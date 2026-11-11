// @source-mirror: src/views/admin/VistaPedidosyFacturas.vue, src/components/pedidos/ModalGestionDespacho.vue, src/components/facturas/ModalCrearFactura.vue, src/components/facturas/ModalCargaMasivaFacturas.vue, src/views/admin/VistaProduccion.vue, src/components/produccion/CalculadoraProduccion.vue, src/components/produccion/GestorOrdenesProduccion.vue
import 'package:flutter/material.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/data/models/order/order_model.dart';
import 'package:fashion_style_mobile/data/services/order_service.dart';

// Modal Gestión de Despacho
class ModalGestionDespachoSheet extends StatefulWidget {
  final OrderModel pedido;
  final VoidCallback onActualizado;

  const ModalGestionDespachoSheet({super.key, required this.pedido, required this.onActualizado});

  @override
  State<ModalGestionDespachoSheet> createState() => _ModalGestionDespachoSheetState();
}

class _ModalGestionDespachoSheetState extends State<ModalGestionDespachoSheet> {
  late String _estado;
  late String _transportadora;
  final TextEditingController _guiaCtrl = TextEditingController();
  final TextEditingController _notasCtrl = TextEditingController();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _estado = widget.pedido.estado;
    _transportadora = widget.pedido.empresaTransportadora.isNotEmpty
        ? widget.pedido.empresaTransportadora
        : OrderService.transportadorasSugeridas.first;
    _guiaCtrl.text = widget.pedido.numeroGuia;
    _notasCtrl.text = widget.pedido.notas;
  }

  Future<void> _guardar() async {
    if ((_estado == 'Enviado' || _estado == 'Entregado')) {
      final guia = _guiaCtrl.text.trim();
      if (!RegExp(r'^[A-Za-z0-9-]{4,40}$').hasMatch(guia)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Para pedidos enviados o entregados, el número de guía es obligatorio (4-40 caracteres alfanuméricos)')),
        );
        return;
      }
    }

    if (_estado == 'Cancelado') {
      final conf = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Cancelar pedido'),
          content: const Text('¿Estás seguro de cancelar este pedido? Se liberará el stock reservado.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: FashionColors.peligro),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sí, cancelar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (conf != true) return;
    }

    setState(() => _guardando = true);
    try {
      await OrderService.instance.actualizarDespacho(
        widget.pedido.id,
        estado: _estado,
        transportadora: _transportadora,
        numeroGuia: _guiaCtrl.text.trim(),
        notas: _notasCtrl.text.trim(),
      );
      widget.onActualizado();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar despacho: $e'), backgroundColor: FashionColors.peligro),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Gestionar Despacho (${widget.pedido.referencia})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _estado,
            decoration: const InputDecoration(labelText: 'Estado del pedido', border: OutlineInputBorder()),
            items: OrderService.estadosPedido.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: (v) => setState(() => _estado = v ?? _estado),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: OrderService.transportadorasSugeridas.contains(_transportadora) ? _transportadora : OrderService.transportadorasSugeridas.first,
            decoration: const InputDecoration(labelText: 'Empresa transportadora', border: OutlineInputBorder()),
            items: OrderService.transportadorasSugeridas.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _transportadora = v ?? _transportadora),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _guiaCtrl,
            decoration: const InputDecoration(labelText: 'Número de guía de despacho', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notasCtrl,
            decoration: const InputDecoration(labelText: 'Notas operativas de despacho', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
            onPressed: _guardando ? null : _guardar,
            child: _guardando ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Actualizar Despacho'),
          ),
        ],
      ),
    );
  }
}
