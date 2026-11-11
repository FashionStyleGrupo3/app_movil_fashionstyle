// @source-mirror: src/views/admin/VistaPedidosyFacturas.vue, src/components/pedidos/ModalGestionDespacho.vue, src/components/facturas/ModalCrearFactura.vue, src/components/facturas/ModalCargaMasivaFacturas.vue, src/views/admin/VistaProduccion.vue, src/components/produccion/CalculadoraProduccion.vue, src/components/produccion/GestorOrdenesProduccion.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/constants/invoice_constants.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/core/utils/error_message.dart';
import 'package:fashion_style_mobile/core/utils/production_helpers.dart';
import 'package:fashion_style_mobile/data/models/invoice/invoice_item_detail.dart';
import 'package:fashion_style_mobile/data/models/invoice/invoice_model.dart';
import 'package:fashion_style_mobile/data/models/order/order_item_detail.dart';
import 'package:fashion_style_mobile/data/models/order/order_model.dart';
import 'package:fashion_style_mobile/data/models/order/order_status.dart';
import 'package:fashion_style_mobile/data/models/production/calculator_dataset.dart';
import 'package:fashion_style_mobile/data/models/production/formula_consumption_model.dart';
import 'package:fashion_style_mobile/data/models/production/production_formula_model.dart';
import 'package:fashion_style_mobile/data/models/production/raw_material_model.dart';
import 'package:fashion_style_mobile/data/services/invoice_pdf_service.dart';
import 'package:fashion_style_mobile/data/services/invoice_service.dart';
import 'package:fashion_style_mobile/data/services/order_service.dart';
import 'package:fashion_style_mobile/data/services/production_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/admin_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/screens/admin/admin_orders_screen.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/orders/bulk_invoice_upload_sheet.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/orders/create_invoice_sheet.dart';
import 'package:fashion_style_mobile/presentation/widgets/admin/orders/dispatch_sheet.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

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
          onPressed: () async {
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Orden de producción generada en estado Planificada')));
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
