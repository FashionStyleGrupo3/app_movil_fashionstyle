// @source-mirror: src/views/admin/VistaPedidosyFacturas.vue, src/components/pedidos/ModalGestionDespacho.vue, src/components/facturas/ModalCrearFactura.vue, src/components/facturas/ModalCargaMasivaFacturas.vue, src/views/admin/VistaProduccion.vue, src/components/produccion/CalculadoraProduccion.vue, src/components/produccion/GestorOrdenesProduccion.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/fashion_theme.dart';
import '../../../core/network/api_response_parser.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/invoice_pdf_generator.dart';
import '../../../data/services/order_and_invoice_service.dart';
import '../../../data/services/production_and_calculator_service.dart';
import '../../layouts/admin_shell_layout.dart';

// ============================================================================
// 1. PEDIDOS ONLINE Y FACTURACIÓN (VistaPedidosyFacturas.vue)
// ============================================================================

class AdminOrdersAndInvoicesScreen extends ConsumerStatefulWidget {
  const AdminOrdersAndInvoicesScreen({super.key});

  @override
  ConsumerState<AdminOrdersAndInvoicesScreen> createState() => _AdminOrdersAndInvoicesScreenState();
}

class _AdminOrdersAndInvoicesScreenState extends ConsumerState<AdminOrdersAndInvoicesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Pedidos
  bool _cargandoPedidos = true;
  List<OrderModel> _pedidos = [];
  String _filtroEstadoPedido = '';
  String _busquedaPedido = '';
  final int _paginaPedidos = 1;

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarPedidos() async {
    setState(() => _cargandoPedidos = true);
    try {
      final res = await OrderService.instance.listarPedidos(
        pagina: _paginaPedidos,
        estado: _filtroEstadoPedido,
        buscar: _busquedaPedido,
      );
      if (mounted) {
        setState(() {
          _pedidos = res.lista;
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ModalGestionDespachoSheet(
        pedido: pedido,
        onActualizado: _cargarPedidos,
      ),
    );
  }

  void _abrirModalCrearFactura() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ModalCrearFacturaSheet(onCreada: _cargarFacturas),
    );
  }

  void _abrirModalCargaMasiva() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ModalCargaMasivaFacturasSheet(onCompletada: _cargarFacturas),
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
              labelColor: FashionColors.negroElegante,
              unselectedLabelColor: FashionColors.textoMuted,
              indicatorColor: FashionColors.rosaCorporativo,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
    final pendientes = _pedidos.where((p) => p.estado == 'Pagado' || p.estado == 'En_Preparacion').length;
    final enTransito = _pedidos.where((p) => p.estado == 'Enviado').length;
    final entregados = _pedidos.where((p) => p.estado == 'Entregado').length;

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
                  _statBox('Por despachar', '$pendientes', FashionColors.aviso),
                  const SizedBox(width: 8),
                  _statBox('En tránsito', '$enTransito', const Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  _statBox('Entregados', '$entregados', FashionColors.verdeExito),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
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
                      padding: const EdgeInsets.all(12),
                      itemCount: _pedidos.length,
                      itemBuilder: (context, index) {
                        final p = _pedidos[index];
                        return Card(
                          elevation: 0.5,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: FashionColors.grisBorde),
                          ),
                          child: ExpansionTile(
                            title: Row(
                              children: [
                                Text(p.referencia, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _colorEstado(p.estado).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
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
                              style: const TextStyle(fontSize: 11, color: FashionColors.textoMuted),
                            ),
                            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            children: [
                              const Divider(),
                              ...p.detalles.map((d) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${d.nombre} (${d.talla}) x${d.cantidad}', style: const TextStyle(fontSize: 12)),
                                    Text(CurrencyFormatter.formatearCOP(d.subtotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )),
                              const SizedBox(height: 8),
                              if (p.numeroGuia.isNotEmpty)
                                Text('Guía: ${p.numeroGuia} (${p.empresaTransportadora})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante, foregroundColor: Colors.white),
                                  onPressed: () => _abrirModalGestionDespacho(p),
                                  icon: const Icon(Icons.local_shipping, size: 16),
                                  label: const Text('Gestionar Despacho', style: TextStyle(fontSize: 12)),
                                ),
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
              ? const Center(child: CircularProgressIndicator(color: FashionColors.rosaCorporativo))
              : _facturas.isEmpty
                  ? const Center(child: Text('No hay facturas emitidas'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _facturas.length,
                      itemBuilder: (context, index) {
                        final f = _facturas[index];
                        return Card(
                          elevation: 0.5,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: FashionColors.grisBorde)),
                          child: ListTile(
                            title: Row(
                              children: [
                                Text(f.numero, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const Spacer(),
                                Text(CurrencyFormatter.formatearCOP(f.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                              ],
                            ),
                            subtitle: Text('${f.fecha ?? ''} · Cliente: ${f.clienteNombre.isNotEmpty ? f.clienteNombre : "Consumidor Final"}', style: const TextStyle(fontSize: 11)),
                            trailing: IconButton(
                              icon: const Icon(Icons.print_outlined, size: 20),
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: col.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(valor, style: TextStyle(fontWeight: FontWeight.bold, color: col, fontSize: 16)),
            Text(label, style: const TextStyle(fontSize: 10, color: FashionColors.textoMuted)),
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

// Modal Gestión de Despacho
class _ModalGestionDespachoSheet extends StatefulWidget {
  final OrderModel pedido;
  final VoidCallback onActualizado;

  const _ModalGestionDespachoSheet({required this.pedido, required this.onActualizado});

  @override
  State<_ModalGestionDespachoSheet> createState() => _ModalGestionDespachoSheetState();
}

class _ModalGestionDespachoSheetState extends State<_ModalGestionDespachoSheet> {
  static const List<String> _flujoOrden = [
    'Pendiente_Pago',
    'Pagado',
    'En_Preparacion',
    'Enviado',
    'Entregado',
  ];

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
    final estadoActual = widget.pedido.estado;
    final idxActual = _flujoOrden.indexOf(estadoActual);
    final idxNuevo = _flujoOrden.indexOf(_estado);

    if (estadoActual == 'Entregado' && _estado != 'Entregado') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El pedido ya fue entregado y no puede cambiar a otra fase.'),
          backgroundColor: FashionColors.peligro,
        ),
      );
      return;
    }

    if (estadoActual == 'Enviado' &&
        (_estado == 'Cancelado' || _estado == 'Rechazado' || _estado == 'Expirado')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El pedido ya fue despachado y enviado, no puede cancelarse desde el seguimiento.'),
          backgroundColor: FashionColors.peligro,
        ),
      );
      return;
    }

    if (idxActual != -1 && idxNuevo != -1 && idxNuevo < idxActual) {
      final nombreFase = OrderService.estadosPedido[_estado] ?? _estado;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede retroceder el pedido a la fase "$nombreFase". El seguimiento ya avanzó.'),
          backgroundColor: FashionColors.peligro,
        ),
      );
      return;
    }

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
            items: OrderService.estadosPedido.entries.map((e) {
              final idxOpcion = _flujoOrden.indexOf(e.key);
              final idxActual = _flujoOrden.indexOf(widget.pedido.estado);
              final esRetroceso = idxActual != -1 && idxOpcion != -1 && idxOpcion < idxActual;
              final bloqueadoEntregado = widget.pedido.estado == 'Entregado' && e.key != 'Entregado';
              final bloqueadoEnviado = widget.pedido.estado == 'Enviado' &&
                  (e.key == 'Cancelado' || e.key == 'Rechazado' || e.key == 'Expirado');
              final deshabilitado = esRetroceso || bloqueadoEntregado || bloqueadoEnviado;

              return DropdownMenuItem(
                value: e.key,
                enabled: !deshabilitado,
                child: Text(
                  deshabilitado ? '${e.value} (Bloqueado)' : e.value,
                  style: TextStyle(
                    color: deshabilitado ? FashionColors.textoMuted : null,
                  ),
                ),
              );
            }).toList(),
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

// Modal Crear Factura
class _ModalCrearFacturaSheet extends StatefulWidget {
  final VoidCallback onCreada;

  const _ModalCrearFacturaSheet({required this.onCreada});

  @override
  State<_ModalCrearFacturaSheet> createState() => _ModalCrearFacturaSheetState();
}

class _ModalCrearFacturaSheetState extends State<_ModalCrearFacturaSheet> {
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
          SnackBar(content: Text('Error al crear factura: $e'), backgroundColor: FashionColors.peligro),
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

// Modal Carga Masiva de Facturas
class _ModalCargaMasivaFacturasSheet extends StatefulWidget {
  final VoidCallback onCompletada;

  const _ModalCargaMasivaFacturasSheet({required this.onCompletada});

  @override
  State<_ModalCargaMasivaFacturasSheet> createState() => _ModalCargaMasivaFacturasSheetState();
}

class _ModalCargaMasivaFacturasSheetState extends State<_ModalCargaMasivaFacturasSheet> {
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
          SnackBar(content: Text('Error en carga masiva: $e'), backgroundColor: FashionColors.peligro),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendo = false);
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Carga Masiva de Facturas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton.icon(
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Plantilla CSV', style: TextStyle(fontSize: 12)),
                onPressed: () => Share.share(InvoiceService.plantillaCsvContenido, subject: 'Plantilla_Facturas.csv'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _subiendo ? null : _seleccionarArchivo,
            icon: const Icon(Icons.attach_file),
            label: Text(_nombreArchivo ?? 'Seleccionar archivo (.csv / .xlsx)'),
          ),
          if (_subiendo) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _progreso, color: FashionColors.rosaCorporativo),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante, foregroundColor: Colors.white),
            onPressed: _subiendo || _rutaArchivo == null ? null : _subir,
            child: const Text('Subir y Procesar'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. PRODUCCIÓN Y COSTOS (VistaProduccion.vue)
// ============================================================================

class AdminProductionScreen extends ConsumerStatefulWidget {
  const AdminProductionScreen({super.key});

  @override
  ConsumerState<AdminProductionScreen> createState() => _AdminProductionScreenState();
}

class _AdminProductionScreenState extends ConsumerState<AdminProductionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _cargando = true;
  CalculatorDataset? _calculadoraData;
  List<Map<String, dynamic>> _materias = [];
  List<Map<String, dynamic>> _formulas = [];
  List<Map<String, dynamic>> _proveedores = [];
  List<Map<String, dynamic>> _ordenes = [];

  // Simulador state
  ProductionFormulaModel? _formulaSeleccionada;
  int _cantidadProducir = 50;
  double _costoManoObra = 35000;
  double _precioVenta = 85000;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _cargarTodo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarTodo() async {
    setState(() => _cargando = true);
    try {
      final resultados = await Future.wait([
        ProductionService.instance.cargarDatosCalculadora(),
        ProductionService.instance.listarMateriasPrimas(),
        ProductionService.instance.listarFormulas(),
        ProductionService.instance.listarProveedores(),
        ProductionService.instance.listarOrdenesProduccion(),
      ]);

      if (mounted) {
        final calcData = resultados[0] as CalculatorDataset;
        setState(() {
          _calculadoraData = calcData;
          _materias = resultados[1] as List<Map<String, dynamic>>;
          _formulas = resultados[2] as List<Map<String, dynamic>>;
          _proveedores = resultados[3] as List<Map<String, dynamic>>;
          _ordenes = resultados[4] as List<Map<String, dynamic>>;
          if (calcData.formulas.isNotEmpty) {
            _formulaSeleccionada = calcData.formulas.first;
          }
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShellLayout(
      currentPath: '/admin/produccion',
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: FashionColors.negroElegante,
              unselectedLabelColor: FashionColors.textoMuted,
              indicatorColor: FashionColors.rosaCorporativo,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              tabs: const [
                Tab(icon: Icon(Icons.calculate_outlined, size: 16), text: 'Simulador Costos'),
                Tab(icon: Icon(Icons.layers_outlined, size: 16), text: 'Materias Primas'),
                Tab(icon: Icon(Icons.format_list_bulleted, size: 16), text: 'Fórmulas'),
                Tab(icon: Icon(Icons.store_mall_directory_outlined, size: 16), text: 'Proveedores'),
                Tab(icon: Icon(Icons.assignment_outlined, size: 16), text: 'Órdenes'),
              ],
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: FashionColors.rosaCorporativo))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _construirSimulador(),
                      _construirMateriasPrimas(),
                      _construirFormulas(),
                      _construirProveedores(),
                      _construirOrdenes(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // 1. SIMULADOR Y CALCULADORA
  Widget _construirSimulador() {
    if (_calculadoraData == null || _calculadoraData!.formulas.isEmpty) {
      return const Center(child: Text('Crea fórmulas de producción para usar el simulador.'));
    }

    final f = _formulaSeleccionada ?? _calculadoraData!.formulas.first;

    // Costo insumos por prenda
    double costoInsumosUnidad = 0;
    bool factible = true;
    final List<String> faltantes = [];

    for (final c in f.consumos) {
      final insumo = _calculadoraData!.buscarMateriaPorId(c.materiaPrimaId);
      final costoUnitario = insumo?.costoUnitario ?? 0;
      final stockActual = insumo?.stockActual ?? 0;
      final requeridoTotal = c.cantidad * _cantidadProducir;

      costoInsumosUnidad += (c.cantidad * costoUnitario);
      if (requeridoTotal > stockActual) {
        factible = false;
        faltantes.add('${insumo?.nombre ?? "Insumo"} (Req: $requeridoTotal, Stock: $stockActual)');
      }
    }

    final costoTotalUnidad = costoInsumosUnidad + _costoManoObra;
    final costoLoteTotal = costoTotalUnidad * _cantidadProducir;
    final ingresoTotal = _precioVenta * _cantidadProducir;
    final utilidadNeta = ingresoTotal - costoLoteTotal;
    final margenPorcentaje = ingresoTotal > 0 ? ((utilidadNeta / ingresoTotal) * 100) : 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<ProductionFormulaModel>(
          initialValue: f,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Fórmula de prenda', border: OutlineInputBorder()),
          items: _calculadoraData!.formulas.map((form) => DropdownMenuItem(value: form, child: Text(form.nombre, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (val) => setState(() => _formulaSeleccionada = val),
        ),
        const SizedBox(height: 12),

        // Parámetros
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: '$_cantidadProducir',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad a confeccionar', border: OutlineInputBorder()),
                onChanged: (v) => setState(() => _cantidadProducir = int.tryParse(v) ?? 1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: '$_costoManoObra',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Mano de obra / ud', border: OutlineInputBorder()),
                onChanged: (v) => setState(() => _costoManoObra = double.tryParse(v) ?? 0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        TextFormField(
          initialValue: '$_precioVenta',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Precio de venta al público (COP)', border: OutlineInputBorder()),
          onChanged: (v) => setState(() => _precioVenta = double.tryParse(v) ?? 0),
        ),
        const SizedBox(height: 16),

        // Factibilidad en bodega
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: factible ? FashionColors.verdeExito.withValues(alpha: 0.08) : FashionColors.aviso.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: factible ? FashionColors.verdeExito.withValues(alpha: 0.3) : FashionColors.aviso.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(factible ? Icons.check_circle : Icons.warning_amber_rounded, color: factible ? FashionColors.verdeExito : FashionColors.aviso, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    factible ? 'Factibilidad en Bodega: Insumos completos' : 'Faltan insumos para este volumen',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: factible ? FashionColors.verdeExito : FashionColors.aviso),
                  ),
                ],
              ),
              if (!factible) ...[
                const SizedBox(height: 4),
                ...faltantes.map((fal) => Text('• $fal', style: const TextStyle(fontSize: 11, color: FashionColors.textoOscuro))),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Desglose de Costos
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: FashionColors.grisBorde)),
          child: Column(
            children: [
              _filaSimulador('Costo insumos (unidad):', CurrencyFormatter.formatearCOP(costoInsumosUnidad)),
              _filaSimulador('Mano de obra (unidad):', CurrencyFormatter.formatearCOP(_costoManoObra)),
              _filaSimulador('Costo total unitario:', CurrencyFormatter.formatearCOP(costoTotalUnidad), negrita: true),
              const Divider(),
              _filaSimulador('Costo total del lote:', CurrencyFormatter.formatearCOP(costoLoteTotal)),
              _filaSimulador('Ingreso proyectado:', CurrencyFormatter.formatearCOP(ingresoTotal)),
              _filaSimulador('Utilidad bruta estimada:', CurrencyFormatter.formatearCOP(utilidadNeta), col: FashionColors.verdeExito, negrita: true),
              _filaSimulador('Margen sobre venta:', '${margenPorcentaje.toStringAsFixed(1)}%', negrita: true),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
          onPressed: (!factible || _cantidadProducir < 1)
              ? null
              : () async {
                  try {
                    await ProductionService.instance.crearOrdenProduccion({
                      'formula_id': f.id,
                      'cantidad': _cantidadProducir,
                      'costo_mano_obra': _costoManoObra,
                      'costo_estimado': costoLoteTotal,
                      'estado': 'planificada',
                    });
                    _cargarTodo();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Orden generada: insumos requeridos reservados y descontados en bodega.'),
                          backgroundColor: FashionColors.verdeExito,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear orden: $e'), backgroundColor: FashionColors.peligro));
                    }
                  }
                },
          icon: const Icon(Icons.post_add),
          label: const Text('Generar Orden de Producción', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        if (!factible) ...[
          const SizedBox(height: 6),
          const Text(
            '⚠️ Insumos insuficientes en bodega para este lote. Revisa la factibilidad arriba.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: FashionColors.peligro, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }

  Widget _filaSimulador(String etq, String val, {bool negrita = false, Color? col}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etq, style: TextStyle(fontSize: 12, color: FashionColors.textoMuted, fontWeight: negrita ? FontWeight.bold : FontWeight.normal)),
          Text(val, style: TextStyle(fontSize: 13, fontWeight: negrita ? FontWeight.bold : FontWeight.w600, color: col ?? FashionColors.textoOscuro)),
        ],
      ),
    );
  }

  // 2. MATERIAS PRIMAS
  Widget _construirMateriasPrimas() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _materias.length,
      itemBuilder: (context, index) {
        final m = _materias[index];
        return Card(
          elevation: 0.5,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.layers, color: Color(0xFF2563EB)),
            title: Text(m['nombre']?.toString() ?? 'Insumo', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Stock: ${m['stock_actual']} ${m['unidad_medida']?['codigo'] ?? ''} · Costo: ${CurrencyFormatter.formatearCOP(JsonParser.toDouble(m['costo_unitario']))}'),
          ),
        );
      },
    );
  }

  // 3. FÓRMULAS
  Widget _construirFormulas() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _formulas.length,
      itemBuilder: (context, index) {
        final f = _formulas[index];
        return Card(
          elevation: 0.5,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.format_list_bulleted, color: Color(0xFF7C3AED)),
            title: Text(f['nombre']?.toString() ?? 'Fórmula', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${(f['consumos'] as List?)?.length ?? 0} insumos configurados'),
          ),
        );
      },
    );
  }

  // 4. PROVEEDORES
  Widget _construirProveedores() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _proveedores.length,
      itemBuilder: (context, index) {
        final p = _proveedores[index];
        return Card(
          elevation: 0.5,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.store, color: Color(0xFF0D9488)),
            title: Text(p['nombre']?.toString() ?? 'Proveedor', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Contacto: ${p['contacto'] ?? ''} · Tel: ${p['telefono'] ?? ''}'),
          ),
        );
      },
    );
  }

  // 5. ÓRDENES DE PRODUCCIÓN
  Widget _construirOrdenes() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _ordenes.length,
      itemBuilder: (context, index) {
        final o = _ordenes[index];
        final id = o['id_orden'] ?? o['id'];
        final estado = o['estado']?.toString() ?? 'planificada';

        return Card(
          elevation: 0.5,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('Orden #$id · ${o['formula']?['nombre'] ?? "Lote"}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Volumen: ${o['cantidad']} prendas · Costo: ${CurrencyFormatter.formatearCOP(JsonParser.toDouble(o['costo_estimado']))}'),
            trailing: estado != 'completada'
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: FashionColors.verdeExito, foregroundColor: Colors.white),
                    onPressed: () async {
                      try {
                        await ProductionService.instance.completarOrdenProduccion(id);
                        _cargarTodo();
                      } catch (_) {}
                    },
                    child: const Text('Completar', style: TextStyle(fontSize: 11)),
                  )
                : const Chip(label: Text('Completada', style: TextStyle(fontSize: 10))),
          ),
        );
      },
    );
  }
}
