// @source-mirror: src/views/admin/VistaAyudaAdmin.vue
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/presentation/layouts/admin_shell_layout.dart';

class _GuiaAyuda {
  final String id;
  final String titulo;
  final IconData icono;
  final String ruta;
  final String resumen;
  final List<String> pasos;
  final bool soloAdmin;

  const _GuiaAyuda({
    required this.id,
    required this.titulo,
    required this.icono,
    required this.ruta,
    required this.resumen,
    required this.pasos,
    this.soloAdmin = false,
  });
}

class AdminHelpScreen extends StatefulWidget {
  const AdminHelpScreen({super.key});

  @override
  State<AdminHelpScreen> createState() => _AdminHelpScreenState();
}

class _AdminHelpScreenState extends State<AdminHelpScreen> {
  final TextEditingController _busquedaCtrl = TextEditingController();
  String _filtroBusqueda = '';
  String? _guiaAbiertaId = 'primeros-pasos';

  static const List<_GuiaAyuda> _guias = [
    _GuiaAyuda(
      id: 'primeros-pasos',
      titulo: 'Primeros pasos',
      icono: Icons.help_outline_rounded,
      ruta: '/admin',
      resumen: 'Cómo está organizado el panel y qué puede hacer cada rol.',
      pasos: [
        'La barra inferior y el menú "Todos" agrupan los módulos del sistema.',
        'El Panel de control muestra ventas, producción e inventario del periodo elegido.',
        'Empleado: opera ventas mostrador, pedidos, inventario y órdenes de confección.',
        'Administrador: además gestiona usuarios, roles, umbrales y la bitácora de auditoría.',
        'Siempre debe existir al menos un administrador en el sistema.',
        'Los cambios que hace otro operador se reflejan en tiempo real.',
      ],
    ),
    _GuiaAyuda(
      id: 'panel',
      titulo: 'Panel de control y reportes',
      icono: Icons.dashboard_outlined,
      ruta: '/admin',
      resumen: 'Indicadores, gráficas y exportación de reportes.',
      pasos: [
        'Elige el periodo (3, 6 o 12 meses) en la parte superior.',
        'Las ventas se separan en tienda física (POS) y tienda en línea.',
        'La gráfica de producción compara unidades planificadas con unidades terminadas.',
        'Los indicadores de caja y margen se actualizan con cada movimiento.',
      ],
    ),
    _GuiaAyuda(
      id: 'inventario',
      titulo: 'Inventario y kárdex',
      icono: Icons.inventory_2_outlined,
      ruta: '/admin/inventario',
      resumen: 'Existencias por talla, movimientos y anulaciones.',
      pasos: [
        'Existencias en vivo: stock actual de cada talla con acciones rápidas de entrada, salida o ajuste.',
        'Kárdex: historial completo de movimientos filtrable por prenda, material, tipo y fechas.',
        'Los movimientos no se eliminan físicamente: si hubo error se anulan y el saldo se recalcula.',
        'Los movimientos generados por producción se revierten al cancelar la orden respectiva.',
      ],
    ),
    _GuiaAyuda(
      id: 'alertas',
      titulo: 'Alertas automáticas de stock',
      icono: Icons.notifications_active_outlined,
      ruta: '/admin/inventario',
      resumen: 'Niveles BAJO, CRÍTICO y AGOTADO.',
      pasos: [
        'Cada venta, pedido o confección revisa el stock y actualiza la alerta correspondiente.',
        'BAJO: el stock llegó al umbral mínimo. CRÍTICO: umbral crítico. AGOTADO: sin existencias.',
        'Al reponer stock por encima del mínimo, la alerta se resuelve automáticamente.',
        'En la pestaña de Alertas puedes marcar como gestionada cualquier novedad.',
      ],
    ),
    _GuiaAyuda(
      id: 'produccion',
      titulo: 'Producción y costos BOM',
      icono: Icons.content_cut_outlined,
      ruta: '/admin/produccion',
      resumen: 'Fórmulas por prenda, calculadora y órdenes de confección.',
      pasos: [
        'Registra materias primas y proveedores; luego arma la fórmula (receta de insumos) de cada prenda.',
        'El simulador estima costo por lote, desperdicio automático, margen y PVP sugerido.',
        'Crear una orden solo la planifica: los insumos aún no se descuentan de bodega.',
        'Al completar la orden (RF-059), distribuye el lote por tallas: en ese instante se descuentan los insumos y entran las prendas al kárdex.',
        'Si necesitas cancelar una orden, el sistema te preguntará si se usaron materiales para ajustar el stock exacto.',
      ],
    ),
    _GuiaAyuda(
      id: 'ventas',
      titulo: 'Punto de venta (POS)',
      icono: Icons.receipt_long_outlined,
      ruta: '/admin/ventas',
      resumen: 'Ventas de mostrador, cambio y comprobantes térmicos.',
      pasos: [
        'Agrega prendas por talla, elige el medio de pago (efectivo, tarjeta, transferencia) y confirma.',
        'El stock se descuenta al instante de la bodega principal.',
        'Imprime o descarga el ticket térmico de 80 mm con desglose de IVA del 19 %.',
        'Si hubo un error en caja, anula la venta y el stock volverá de inmediato al inventario.',
      ],
    ),
    _GuiaAyuda(
      id: 'pedidos',
      titulo: 'Pedidos en línea y facturación',
      icono: Icons.local_shipping_outlined,
      ruta: '/admin/pedidos',
      resumen: 'Despachos web, guías de envío y facturas electrónicas.',
      pasos: [
        'Los pedidos pagados con Wompi ingresan en estado "Pagado".',
        'Cámbialos secuencialmente a preparación, enviado o entregado según el flujo logístico.',
        'Registra la transportadora y el número de guía al momento del despacho.',
        'Cada orden genera su factura con consecutivo único e impresión PDF.',
      ],
    ),
    _GuiaAyuda(
      id: 'prendas',
      titulo: 'Gestión de prendas',
      icono: Icons.checkroom_outlined,
      ruta: '/admin/prendas',
      resumen: 'Catálogo, variantes de talla, fotos y estado.',
      pasos: [
        'Crea la prenda con su código de referencia, categoría y variantes de talla (XS a XXL).',
        'Sube fotografías de catálogo y define precios por variante si difieren.',
        'Prendas con historial de ventas o confección no se eliminan: desactívalas para ocultarlas de la tienda pública.',
      ],
    ),
    _GuiaAyuda(
      id: 'pagos',
      titulo: 'Pagos y dispersión',
      icono: Icons.account_balance_outlined,
      ruta: '/admin/pagos',
      resumen: 'Pasarela Wompi, llaves API y canales de recaudo.',
      pasos: [
        'Configura tus llaves pública y privada de Wompi (modo sandbox o producción).',
        'Revisa los ingresos consolidados por canal de pago.',
        'Si un pago en línea no se confirma a tiempo, el stock reservado se libera a los 15 minutos.',
      ],
    ),
    _GuiaAyuda(
      id: 'usuarios',
      titulo: 'Clientes, usuarios y roles',
      icono: Icons.people_outline,
      ruta: '/admin/seguridad',
      resumen: 'Directorio de cuentas, asignación de roles y control de acceso.',
      pasos: [
        'Toda cuenta registrada nace con rol cliente.',
        'El administrador puede elevar permisos a empleado o administrador.',
        'Monitorea el último acceso registrado de cada operador.',
        'Desactivar una cuenta revoca sus accesos de inmediato.',
      ],
    ),
    _GuiaAyuda(
      id: 'bitacora',
      titulo: 'Bitácora de auditoría',
      icono: Icons.history_edu_outlined,
      ruta: '/admin/seguridad/auditoria',
      resumen: 'Quién modificó qué, fecha, hora e IP.',
      soloAdmin: true,
      pasos: [
        'Registro inmutable de inicios de sesión, anulaciones, cambios de precio y órdenes.',
        'Filtra por usuario, módulo o fecha para auditar operaciones sensibles.',
      ],
    ),
    _GuiaAyuda(
      id: 'mensajes',
      titulo: 'Mensajes de contacto y PQRS',
      icono: Icons.mail_outline,
      ruta: '/admin/mensajes',
      resumen: 'Bandeja de solicitudes enviadas desde la tienda pública.',
      pasos: [
        'Los clientes radican peticiones, quejas o reclamos desde la sección Contacto.',
        'Filtra por estado (nuevos, leídos, respondidos) o tipo de solicitud.',
        'Al redactar la respuesta desde el panel, el sistema notifica por correo electrónico al cliente.',
      ],
    ),
  ];

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final termino = _filtroBusqueda.trim().toLowerCase();
    final guiasFiltradas = _guias.where((g) {
      if (termino.isEmpty) return true;
      final matchTitulo = g.titulo.toLowerCase().contains(termino);
      final matchResumen = g.resumen.toLowerCase().contains(termino);
      final matchPasos = g.pasos.any((p) => p.toLowerCase().contains(termino));
      return matchTitulo || matchResumen || matchPasos;
    }).toList();

    return AdminShellLayout(
      currentPath: '/admin/ayuda',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          // Banner de bienvenida al Centro de Ayuda
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FashionColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: FashionColors.inkPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'CENTRO DE AYUDA',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: FashionColors.inkPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '¿Cómo usar el panel de FashionStyle?',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: FashionColors.inkPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Guías de operación paso a paso para el personal y operadores del sistema. Busca una tarea específica o abre el módulo deseado.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: FashionColors.inkSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _busquedaCtrl,
                  onChanged: (val) => setState(() => _filtroBusqueda = val),
                  decoration: InputDecoration(
                    hintText: 'Ej. anular movimiento, completar orden, rol...',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: FashionColors.inkSecondary.withValues(alpha: 0.6)),
                    prefixIcon: const Icon(Icons.search, size: 20, color: FashionColors.inkSecondary),
                    suffixIcon: _filtroBusqueda.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _busquedaCtrl.clear();
                              setState(() => _filtroBusqueda = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: FashionColors.canvasBackground,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: FashionColors.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: FashionColors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: FashionColors.inkPrimary, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (guiasFiltradas.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FashionColors.borderSubtle),
              ),
              child: Column(
                children: [
                  const Icon(Icons.search_off_rounded, size: 40, color: FashionColors.inkSecondary),
                  const SizedBox(height: 8),
                  Text(
                    'No encontramos guías para "$_filtroBusqueda"',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: FashionColors.inkSecondary),
                  ),
                ],
              ),
            )
          else
            ...guiasFiltradas.map((guia) {
              final estaAbierta = _guiaAbiertaId == guia.id || _filtroBusqueda.isNotEmpty;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: estaAbierta ? FashionColors.inkPrimary.withValues(alpha: 0.25) : FashionColors.borderSubtle,
                  ),
                ),
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() {
                          _guiaAbiertaId = _guiaAbiertaId == guia.id ? null : guia.id;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: FashionColors.canvasBackground,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(guia.icono, size: 20, color: FashionColors.inkPrimary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        guia.titulo,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: FashionColors.inkPrimary,
                                        ),
                                      ),
                                      if (guia.soloAdmin) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: FashionColors.brandAccent.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'ADMIN',
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w700,
                                              color: FashionColors.brandAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    guia.resumen,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: FashionColors.inkSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              estaAbierta ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              color: FashionColors.inkSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (estaAbierta) ...[
                      const Divider(height: 1, color: FashionColors.borderSubtle),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...guia.pasos.asMap().entries.map((entry) {
                              final idx = entry.key + 1;
                              final paso = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      margin: const EdgeInsets.only(top: 1, right: 8),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: FashionColors.canvasBackground,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: FashionColors.borderSubtle),
                                      ),
                                      child: Text(
                                        '$idx',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: FashionColors.inkPrimary,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        paso,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          height: 1.4,
                                          color: FashionColors.inkPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: FashionColors.brandAccent,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                                onPressed: () => context.go(guia.ruta),
                                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                                label: Text(
                                  'Ir a ${guia.titulo}',
                                  style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
