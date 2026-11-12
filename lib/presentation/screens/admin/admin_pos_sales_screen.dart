// @source-mirror: src/views/admin/VistaGestionPrendas.vue, src/composables/useGestionPrendas.js, src/views/admin/VistaVentasPOS.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/constants/payment_constants.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/core/utils/admin_export_dialog.dart';
import 'package:fashion_style_mobile/data/models/pos/pos_sale_model.dart';
import 'package:fashion_style_mobile/data/models/pos/pos_sales_summary.dart';
import 'package:fashion_style_mobile/data/services/invoice_pdf_service.dart';
import 'package:fashion_style_mobile/data/services/pos_sale_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/admin_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/pos/new_pos_sale_sheet.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminPosSalesScreen extends ConsumerStatefulWidget {
  const AdminPosSalesScreen({super.key});

  @override
  ConsumerState<AdminPosSalesScreen> createState() => _AdminPosSalesScreenState();
}

class _AdminPosSalesScreenState extends ConsumerState<AdminPosSalesScreen> {
  bool _cargando = true;
  String? _error;
  List<PosSaleModel> _ventas = [];
  PosSalesSummary? _resumen;
  String _filtroMedioPago = '';
  final int _pagina = 1;

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  Future<void> _cargarVentas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultados = await Future.wait([
        PosSaleService.instance.obtenerResumenVentas(),
        PosSaleService.instance.listarVentas(pagina: _pagina, medioPago: _filtroMedioPago),
      ]);

      if (mounted) {
        final dynamic rawRes = resultados[0];
        final PosSalesSummary res = rawRes is PosSalesSummary
            ? rawRes
            : (rawRes is Map<String, dynamic>
                ? PosSalesSummary.fromJson(rawRes)
                : PosSalesSummary.fromJson(const {}));
        final pag = resultados[1] as PaginatedResponse<PosSaleModel>;
        setState(() {
          _resumen = res;
          _ventas = pag.lista;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiClient.obtenerMensajeError(e, 'No se pudieron cargar las ventas del punto de venta.');
          _cargando = false;
        });
      }
    }
  }

  Future<void> _cancelarVenta(PosSaleModel v) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anular venta POS'),
        content: Text('¿Deseas cancelar la venta "${v.codigo}"? Las unidades volverán al inventario.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Volver')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FashionColors.peligro),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Anular Venta', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await PosSaleService.instance.cancelarVenta(v.id);
      _cargarVentas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Venta anulada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No fue posible anular la venta.')),
            backgroundColor: FashionColors.peligro,
          ),
        );
      }
    }
  }

  void _exportarVentasPos() {
    if (_ventas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay ventas registradas para exportar')),
      );
      return;
    }

    final encabezados = ['Código', 'Fecha', 'Cliente', 'Doc', 'Medio Pago', 'Total', 'Cajero'];
    final filas = _ventas.map((v) {
      return [
        v.codigo,
        v.fecha,
        v.clienteNombre,
        v.clienteDocumento,
        v.medioPago.toUpperCase(),
        CurrencyFormatter.formatearCOP(v.total),
        v.usuarioNombre,
      ];
    }).toList();

    AdminExportDialog.mostrarDialogoExportacion(
      context,
      titulo: 'Reporte de Ventas POS de Mostrador',
      encabezados: encabezados,
      filas: filas,
      nombreArchivo: 'ventas_pos_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  void _abrirModalNuevaVenta() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ModalNuevaVentaPos(onCobrada: _cargarVentas),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminShellLayout(
      currentPath: '/admin/ventas',
      child: Column(
        children: [
          // RESUMEN FINANCIERO SUPERIOR
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    _cardResumen('Ventas Hoy', '${_resumen?.ventasHoy ?? 0}', FashionColors.rosaCorporativo),
                    const SizedBox(width: 8),
                    _cardResumen('Ingreso Hoy', CurrencyFormatter.formatearCOP(_resumen?.montoHoy ?? 0), FashionColors.verdeExito),
                    const SizedBox(width: 8),
                    _cardResumen('Caja Activa', CurrencyFormatter.formatearCOP(_resumen?.montoActivas ?? 0), const Color(0xFF2563EB)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _chipMedio('', 'Todos'),
                            ...mediosPagoPos.entries.map((e) => _chipMedio(e.key, e.value)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.file_download_outlined),
                      tooltip: 'Exportar Reporte (PDF / Excel)',
                      onPressed: _exportarVentasPos,
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FashionColors.primaryCorporate,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _abrirModalNuevaVenta,
                      icon: const Icon(Icons.point_of_sale, size: 16),
                      label: Text('Nueva Venta', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // LISTA DE VENTAS REGISTRADAS
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: FashionColors.brandAccent))
                : _error != null
                    ? Center(child: Text(_error!))
                    : _ventas.isEmpty
                        ? const Center(child: Text('No hay ventas registradas'))
                        : ListView.builder(
                            padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 96),
                            itemCount: _ventas.length,
                            itemBuilder: (context, index) {
                              final v = _ventas[index];
                              final esActiva = v.estado == 'completada' || v.estado == 'activa';

                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: const BorderSide(color: FashionColors.borderSubtle),
                                ),
                                child: ExpansionTile(
                                  title: Row(
                                    children: [
                                      Text(v.codigo, style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, fontSize: 13, color: FashionColors.inkPrimary)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: esActiva ? FashionColors.statusSuccess.withValues(alpha: 0.12) : FashionColors.statusDanger.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: esActiva ? FashionColors.statusSuccess.withValues(alpha: 0.3) : FashionColors.statusDanger.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          v.medioPago.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: esActiva ? FashionColors.statusSuccess : FashionColors.statusDanger,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        CurrencyFormatter.formatearCOP(v.total),
                                        style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, fontSize: 14, color: FashionColors.inkPrimary),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    '${v.fecha ?? ''} · Cliente: ${v.clienteNombre.isNotEmpty ? v.clienteNombre : "Consumidor"}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FashionColors.inkSecondary),
                                  ),
                                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                  children: [
                                    const Divider(),
                                    ...v.detalles.map((d) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('${d.nombre} (${d.talla}) x${d.cantidad}', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                                          Text(CurrencyFormatter.formatearCOP(d.subtotal), style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    )),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: FashionColors.canvasBackground,
                                            foregroundColor: FashionColors.inkPrimary,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          onPressed: () => InvoicePdfGenerator.generarYCompartirReciboPos(v),
                                          icon: const Icon(Icons.print, size: 16),
                                          label: Text('Imprimir Recibo', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600)),
                                        ),
                                        const Spacer(),
                                        if (esActiva)
                                          TextButton(
                                            style: TextButton.styleFrom(foregroundColor: FashionColors.statusDanger),
                                            onPressed: () => _cancelarVenta(v),
                                            child: Text('Anular Venta', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w600)),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _cardResumen(String label, String valor, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: col.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(valor, style: TextStyle(fontWeight: FontWeight.bold, color: col, fontSize: 14)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: FashionColors.textoMuted)),
          ],
        ),
      ),
    );
  }

  Widget _chipMedio(String val, String label) {
    final sel = _filtroMedioPago == val;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 10, color: sel ? Colors.white : FashionColors.textoOscuro)),
        selected: sel,
        selectedColor: FashionColors.negroElegante,
        onSelected: (_) {
          setState(() => _filtroMedioPago = val);
          _cargarVentas();
        },
      ),
    );
  }
}
