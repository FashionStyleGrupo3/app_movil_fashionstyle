// @source-mirror: src/views/admin/VistaConfiguracionPagos.vue, src/views/admin/VistaUsuariosYClientes.vue, src/views/admin/VistaAuditoria.vue, src/views/admin/VistaEditarCuenta.vue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/data/models/payment/bank_account_config.dart';
import 'package:fashion_style_mobile/data/models/payment/parallel_payment_control.dart';
import 'package:fashion_style_mobile/data/services/payment_config_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/admin_shell_layout.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminPaymentsConfigScreen extends ConsumerStatefulWidget {
  const AdminPaymentsConfigScreen({super.key});

  @override
  ConsumerState<AdminPaymentsConfigScreen> createState() => _AdminPaymentsConfigScreenState();
}

class _AdminPaymentsConfigScreenState extends ConsumerState<AdminPaymentsConfigScreen> {
  bool _cargando = true;
  ParallelPaymentControl? _control;
  List<BankAccountConfig> _cuentas = [];
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final ctrl = await PaymentConfigService.instance.obtenerControlParaleloPagos();
      final cuentas = await PaymentConfigService.instance.obtenerCuentasDispersion();
      if (mounted) {
        setState(() {
          _control = ctrl;
          _cuentas = cuentas;
          _cargando = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  double get _sumaPorcentajes {
    return _cuentas.where((c) => c.activa).fold(0.0, (sum, c) => sum + c.porcentaje);
  }

  void _abrirModalCuenta([BankAccountConfig? cuentaEditar]) {
    final bancoCtrl = TextEditingController(text: cuentaEditar?.banco ?? 'Bancolombia');
    final titularCtrl = TextEditingController(text: cuentaEditar?.titular ?? '');
    final numCtrl = TextEditingController(text: cuentaEditar?.numeroCuenta ?? '');
    final porcCtrl = TextEditingController(text: '${cuentaEditar?.porcentaje ?? 20}');
    String tipo = cuentaEditar?.tipo ?? 'ahorros';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(cuentaEditar != null ? 'Editar Cuenta de Dispersión' : 'Agregar Cuenta Bancaria', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(controller: bancoCtrl, decoration: const InputDecoration(labelText: 'Entidad Bancaria *', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: titularCtrl, decoration: const InputDecoration(labelText: 'Titular de la cuenta *', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: numCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Número de cuenta *', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: porcCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Porcentaje de dispersión (%) *', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante, foregroundColor: Colors.white),
              onPressed: () {
                final porc = double.tryParse(porcCtrl.text) ?? 0;
                final nueva = BankAccountConfig(
                  id: cuentaEditar?.id ?? (_cuentas.isEmpty ? 1 : (_cuentas.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1)),
                  banco: bancoCtrl.text.trim(),
                  tipoCuenta: tipo,
                  numeroCuenta: numCtrl.text.trim(),
                  titular: titularCtrl.text.trim(),
                  concepto: 'Dispersión de fondos',
                  porcentaje: porc,
                  activa: cuentaEditar?.activa ?? true,
                );

                setState(() {
                  if (cuentaEditar != null) {
                    final idx = _cuentas.indexOf(cuentaEditar);
                    if (idx != -1) _cuentas[idx] = nueva;
                  } else {
                    _cuentas.add(nueva);
                  }
                });
                Navigator.pop(ctx);
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarConfiguracion() async {
    final validacion = PaymentConfigService.instance.validarPorcentajesDispersion(_cuentas);
    if (!validacion['valido']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validacion['mensaje']), backgroundColor: FashionColors.peligro),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      await PaymentConfigService.instance.guardarConfiguracionPasarela(
        cuentasBancarias: _cuentas,
      );
      _cargarDatos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración de dispersión guardada exitosamente')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No se pudo guardar la configuración de pagos.')),
            backgroundColor: FashionColors.peligro,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalConsolidado = _control?.recaudoTotalConsolidado ?? 0;
    final dispersion = PaymentConfigService.instance.calcularDispersionFondos(totalConsolidado, _cuentas);

    return AdminShellLayout(
      currentPath: '/admin/pagos',
      child: _cargando
          ? const Center(child: CircularProgressIndicator(color: FashionColors.rosaCorporativo))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // CONTROL PARALELO DE INGRESOS
                Text('Control Paralelo de Recaudos', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _cardRecaudo('Wompi Online', CurrencyFormatter.formatearCOP(_control?.recaudoWompiOnline ?? 0), '${_control?.cantidadPedidosPagados ?? 0} pedidos', FashionColors.brandAccent),
                    const SizedBox(width: 8),
                    _cardRecaudo('POS Mostrador', CurrencyFormatter.formatearCOP(_control?.recaudoPosMostrador ?? 0), '${_control?.cantidadVentasPos ?? 0} ventas', FashionColors.atelierJade),
                    const SizedBox(width: 8),
                    _cardRecaudo('Consolidado', CurrencyFormatter.formatearCOP(totalConsolidado), '${_control?.facturasEmitidas ?? 0} facturas', FashionColors.statusSuccess),
                  ],
                ),

                const SizedBox(height: 24),

                // DISPERSIÓN DE FONDOS
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Dispersión en Cuentas Bancarias',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _abrirModalCuenta(),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Agregar Cuenta'),
                    ),
                  ],
                ),
                Text('Suma activa: ${_sumaPorcentajes.toStringAsFixed(1)}% (debe ser exactamente 100%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _sumaPorcentajes == 100 ? FashionColors.verdeExito : FashionColors.peligro)),
                const SizedBox(height: 10),

                ..._cuentas.map((c) {
                  final asignado = dispersion.where((d) => d.id == c.id).firstOrNull;
                  final montoDispersion = asignado?.montoAsignado ?? 0.0;
                  return Card(
                    elevation: 0.5,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: FashionColors.grisBorde)),
                    child: ListTile(
                      leading: const Icon(Icons.account_balance, color: FashionColors.pizarra),
                      title: Text('${c.banco} · ${c.titular}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('Cuenta ${c.numeroCuenta} (${c.tipoCuenta}) · ${c.porcentaje}% activo\nAsignado: ${CurrencyFormatter.formatearCOP(montoDispersion)}', style: const TextStyle(fontSize: 11)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _abrirModalCuenta(c)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: FashionColors.peligro),
                            onPressed: () => setState(() => _cuentas.remove(c)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FashionColors.brandAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _guardando ? null : _guardarConfiguracion,
                  child: _guardando ? const CircularProgressIndicator(color: Colors.white) : Text('Guardar Configuración de Dispersión', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 96),
              ],
            ),
    );
  }

  Widget _cardRecaudo(String titulo, String monto, String sub, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: col.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: col.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(monto, style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700, color: col, fontSize: 13)),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(titulo, style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary)),
            ),
            const SizedBox(height: 1),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(sub, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: FashionColors.inkSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. CLIENTES Y USUARIOS STAFF (VistaUsuariosYClientes.vue)
// ============================================================================
