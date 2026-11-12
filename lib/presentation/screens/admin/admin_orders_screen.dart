import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/change_bus.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/data/models/invoice/invoice_model.dart';
import 'package:fashion_style_mobile/data/models/order/order_model.dart';
import 'package:fashion_style_mobile/data/services/invoice_pdf_service.dart';
import 'package:fashion_style_mobile/data/services/invoice_service.dart';
import 'package:fashion_style_mobile/data/services/order_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/admin_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/orders/bulk_invoice_upload_sheet.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/orders/create_invoice_sheet.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/orders/dispatch_sheet.dart';
import 'package:fashion_style_mobile/core/utils/admin_export_dialog.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminOrdersAndInvoicesScreen extends ConsumerStatefulWidget {
  const AdminOrdersAndInvoicesScreen({super.key});

  @override
  ConsumerState<AdminOrdersAndInvoicesScreen> createState() => _AdminOrdersAndInvoicesScreenState();
}

class _AdminOrdersAndInvoicesScreenState extends ConsumerState<AdminOrdersAndInvoicesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription<DataChangeEvent>? _busSub;

  // Pedidos
  bool _cargandoPedidos = true;
  List<OrderModel> _pedidos = [];
  String _filtroEstadoPedido = '';
  String _busquedaPedido = '';
  final int _paginaPedidos = 1;

  // KPI counters
  int _kpiPendientes = 0;
  int _kpiEnTransito = 0;
  int _kpiEntregados = 0;

  // Facturas
  bool _cargandoFacturas = true;
  List<InvoiceModel> _facturas = [];
  String _busquedaFactura = '';
  final int _paginaFacturas = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarPedidos();
    _cargarFacturas();

    _busSub = ChangeBus.instance.stream.listen((evento) {
      if (evento.recurso == 'pedidos' || evento.recurso == 'dashboard' || evento.recurso == 'app_resumed') {
        _cargarPedidos();
        _cargarFacturas();
      }
    });
  }

  @override
  void dispose() {
    _busSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarPedidos() async {
    setState(() => _cargandoPedidos = true);
    try {
      final resFuture = OrderService.instance.listarPedidos(
        pagina: _paginaPedidos,
        estado: _filtroEstadoPedido,
        buscar: _busquedaPedido,
        porPagina: 50,
      );
      final statsFuture = OrderService.instance.listarPedidos(
        pagina: 1,
        porPagina: 100,
      );

      final resultados = await Future.wait([resFuture, statsFuture]);
      final res = resultados[0];
      final stats = resultados[1];

      if (mounted) {
        setState(() {
          _pedidos = res.lista;
          _kpiPendientes = stats.lista.where((p) => p.estado == 'Pagado' || p.estado == 'En_Preparacion').length;
          _kpiEnTransito = stats.lista.where((p) => p.estado == 'Enviado').length;
          _kpiEntregados = stats.lista.where((p) => p.estado == 'Entregado').length;
          _cargandoPedidos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargandoPedidos = false;
        });
      }
    }
  }

  Future<void> _cargarFacturas() async {
    setState(() => _cargandoFacturas = true);
    try {
      final res = await InvoiceService.instance.listarFacturas(
        pagina: _paginaFacturas,
        buscar: _busquedaFactura,
      );
      if (mounted) {
        setState(() {
          _facturas = res.lista;
          _cargandoFacturas = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargandoFacturas = false;
        });
      }
    }
  }

  void _abrirModalGestionDespacho(OrderModel pedido) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ModalGestionDespachoSheet(
        pedido: pedido,
        onActualizado: _cargarPedidos,
      ),
    );
  }

  Future<void> _avanzarEstadoRapido(OrderModel pedido, String nuevoEstado, {String? transportadora, String? guia}) async {
    try {
      await OrderService.instance.actualizarDespacho(
        pedido.id,
        estado: nuevoEstado,
        transportadora: transportadora,
        numeroGuia: guia,
      );
      ChangeBus.instance.notifyAll(['pedidos', 'dashboard']);
      await _cargarPedidos();
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pedido ${pedido.referencia} actualizado a ${OrderService.estadosPedido[nuevoEstado] ?? nuevoEstado}'),
            backgroundColor: FashionColors.verdeExito,
            duration: const Duration(milliseconds: 1600),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No se pudo actualizar el estado.')),
            backgroundColor: FashionColors.peligro,
            duration: const Duration(milliseconds: 1600),
          ),
        );
      }
    }
  }

  void _abrirModalCrearFactura() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ModalCrearFacturaSheet(onCreada: _cargarFacturas),
    );
  }

  void _abrirModalCargaMasiva() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ModalCargaMasivaFacturasSheet(onCompletada: _cargarFacturas),
    );
  }

  void _exportarPedidos() {
    if (_pedidos.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay pedidos para exportar'),
          duration: Duration(milliseconds: 1600),
        ),
      );
      return;
    }

    final encabezados = ['Referencia', 'Fecha', 'Cliente', 'Estado', 'Total', 'Transportadora', 'Guía'];
    final filas = _pedidos.map((p) {
      return [
        p.referencia,
        p.fechaPedido ?? '',
        p.clienteNombre,
        OrderService.estadosPedido[p.estado] ?? p.estado,
        CurrencyFormatter.formatearCOP(p.total),
        p.empresaTransportadora,
        p.numeroGuia,
      ];
    }).toList();

    AdminExportDialog.mostrarDialogoExportacion(
      context,
      titulo: 'Reporte de Pedidos y Despachos',
      encabezados: encabezados,
      filas: filas,
      nombreArchivo: 'pedidos_despacho_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminShellLayout(
      currentPath: '/admin/pedidos',
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: FashionColors.inkPrimary,
              unselectedLabelColor: FashionColors.inkSecondary,
              indicatorColor: FashionColors.brandAccent,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 12),
              tabs: const [
                Tab(icon: Icon(Icons.local_shipping_outlined, size: 18), text: 'Pedidos Online'),
                Tab(icon: Icon(Icons.receipt_outlined, size: 18), text: 'Facturas DIAN'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _construirPestanaPedidos(),
                _construirPestanaFacturas(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirPestanaPedidos() {
    return Column(
      children: [
        // RESUMEN Y FILTROS
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  _statBox('Por despachar', '$_kpiPendientes', FashionColors.aviso),
                  const SizedBox(width: 8),
                  _statBox('En tránsito', '$_kpiEnTransito', const Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  _statBox('Entregados', '$_kpiEntregados', FashionColors.verdeExito),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Buscar por referencia, cliente o guía...',
                        prefixIcon: Icon(Icons.search, size: 18),
                        contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        _busquedaPedido = val;
                        _cargarPedidos();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.file_download_outlined),
                    tooltip: 'Exportar Pedidos (PDF / Excel)',
                    onPressed: _exportarPedidos,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chipEstadoPedido('', 'Todos'),
                    ...OrderService.estadosPedido.entries.map((e) => _chipEstadoPedido(e.key, e.value)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // LISTA DE PEDIDOS
        Expanded(
          child: _cargandoPedidos
              ? const Center(child: CircularProgressIndicator(color: FashionColors.rosaCorporativo))
              : _pedidos.isEmpty
                  ? const Center(child: Text('No hay pedidos en este estado'))
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 96),
                      itemCount: _pedidos.length,
                      itemBuilder: (context, index) {
                        final p = _pedidos[index];
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: FashionColors.borderSubtle),
                          ),
                          child: ExpansionTile(
                            title: Row(
                              children: [
                                Text(p.referencia, style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, fontSize: 13, color: FashionColors.inkPrimary)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: _colorEstado(p.estado).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: _colorEstado(p.estado).withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    OrderService.estadosPedido[p.estado] ?? p.estado,
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _colorEstado(p.estado)),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              '${p.fechaPedido ?? ''} · Cliente: ${p.clienteNombre} · Total: ${CurrencyFormatter.formatearCOP(p.total)}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FashionColors.inkSecondary),
                            ),
                            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            children: [
                              const Divider(),
                              ...p.detalles.map((d) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${d.nombre} (${d.talla}) x${d.cantidad}', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                                    Text(CurrencyFormatter.formatearCOP(d.subtotal), style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              )),
                              const SizedBox(height: 8),
                              if (p.numeroGuia.isNotEmpty)
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Guía: ${p.numeroGuia} (${p.empresaTransportadora})',
                                        style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy_rounded, size: 16, color: FashionColors.brandAccent),
                                      tooltip: 'Copiar Guía',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: p.numeroGuia));
                                        ScaffoldMessenger.of(context).clearSnackBars();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Número de guía "${p.numeroGuia}" copiado al portapapeles'),
                                            duration: const Duration(milliseconds: 1600),
                                            backgroundColor: FashionColors.inkPrimary,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 12),
                              Builder(
                                builder: (context) {
                                  final est = p.estado.toLowerCase();
                                  final estaBloqueado = est == 'cancelado' || est == 'rechazado' || est == 'entregado';

                                  if (estaBloqueado) {
                                    return Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: FashionColors.surfaceSecondary,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Pedido ${p.estado}',
                                          style: GoogleFonts.poppins(fontSize: 12, color: FashionColors.textoMuted, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    );
                                  }

                                  return Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.end,
                                    children: [
                                      if (p.estado == 'Pagado')
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF2563EB),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          icon: const Icon(Icons.inventory_2_outlined, size: 15),
                                          label: Text('Pasar a En Preparación', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                                          onPressed: () => _avanzarEstadoRapido(p, 'En_Preparacion'),
                                        ),
                                      if (p.estado == 'En_Preparacion')
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF4F46E5),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          icon: const Icon(Icons.local_shipping_outlined, size: 15),
                                          label: Text('Despachar y Enviar', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                                          onPressed: () => _abrirModalGestionDespacho(p),
                                        ),
                                      if (p.estado == 'Enviado')
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: FashionColors.verdeExito,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          icon: const Icon(Icons.check_circle_outline, size: 15),
                                          label: Text('Marcar como Entregado', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                                          onPressed: () => _avanzarEstadoRapido(p, 'Entregado', transportadora: p.empresaTransportadora, guia: p.numeroGuia),
                                        ),
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: FashionColors.textoPrincipal,
                                          side: const BorderSide(color: FashionColors.bordeClaro),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        icon: const Icon(Icons.edit_note, size: 16),
                                        label: Text('Gestionar Despacho', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                                        onPressed: () => _abrirModalGestionDespacho(p),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _construirPestanaFacturas() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar factura por N° o cliente...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    _busquedaFactura = val;
                    _cargarFacturas();
                  },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: FashionColors.rosaCorporativo),
                onPressed: _abrirModalCargaMasiva,
                icon: const Icon(Icons.upload_file, size: 16),
                label: const Text('Masivo', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante, foregroundColor: Colors.white),
                onPressed: _abrirModalCrearFactura,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Crear', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        Expanded(
          child: _cargandoFacturas
              ? const Center(child: CircularProgressIndicator(color: FashionColors.brandAccent))
              : _facturas.isEmpty
                  ? const Center(child: Text('No hay facturas emitidas'))
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 96),
                      itemCount: _facturas.length,
                      itemBuilder: (context, index) {
                        final f = _facturas[index];
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: FashionColors.borderSubtle)),
                          child: ListTile(
                            title: Row(
                              children: [
                                Text(f.numero, style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, fontSize: 13, color: FashionColors.inkPrimary)),
                                const Spacer(),
                                Text(CurrencyFormatter.formatearCOP(f.total), style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, fontSize: 14, color: FashionColors.inkPrimary)),
                              ],
                            ),
                            subtitle: Text('${f.fecha ?? ''} · Cliente: ${f.clienteNombre.isNotEmpty ? f.clienteNombre : "Consumidor Final"}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FashionColors.inkSecondary)),
                            trailing: IconButton(
                              icon: const Icon(Icons.print_outlined, size: 20, color: FashionColors.inkPrimary),
                              tooltip: 'Imprimir / Compartir Factura PDF',
                              onPressed: () => InvoicePdfGenerator.generarYCompartirFactura(f),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _statBox(String label, String valor, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(color: col.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(valor, style: TextStyle(fontWeight: FontWeight.bold, color: col, fontSize: 16)),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: const TextStyle(fontSize: 10, color: FashionColors.textoMuted)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipEstadoPedido(String val, String label) {
    final sel = _filtroEstadoPedido == val;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 10, color: sel ? Colors.white : FashionColors.textoOscuro)),
        selected: sel,
        selectedColor: FashionColors.negroElegante,
        onSelected: (_) {
          setState(() => _filtroEstadoPedido = val);
          _cargarPedidos();
        },
      ),
    );
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'Pagado':
      case 'Entregado':
        return FashionColors.verdeExito;
      case 'Enviado':
      case 'En_Preparacion':
        return const Color(0xFF2563EB);
      case 'Pendiente_Pago':
        return FashionColors.aviso;
      default:
        return FashionColors.peligro;
    }
  }
}
