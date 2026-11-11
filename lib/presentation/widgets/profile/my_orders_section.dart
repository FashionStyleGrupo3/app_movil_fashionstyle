// @source-mirror: src/views/publico/VistaMiPerfil.vue, src/components/perfil/SeccionMisPedidos.vue, src/components/perfil/SeccionFavoritos.vue
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/data/models/order/order_model.dart';
import 'package:fashion_style_mobile/data/services/order_service.dart';
import 'package:fashion_style_mobile/data/services/product_service.dart';
import 'package:fashion_style_mobile/data/services/wompi_service.dart';
import 'package:fashion_style_mobile/presentation/providers/cart_provider.dart';
import 'package:fashion_style_mobile/presentation/widgets/common/atelier_vector_art.dart';
import 'package:fashion_style_mobile/presentation/widgets/payment/wompi_checkout_modal.dart';
import 'package:go_router/go_router.dart';

class SeccionMisPedidos extends ConsumerStatefulWidget {
  const SeccionMisPedidos({super.key});

  @override
  ConsumerState<SeccionMisPedidos> createState() => _SeccionMisPedidosState();
}

class _SeccionMisPedidosState extends ConsumerState<SeccionMisPedidos> {
  bool _cargando = true;
  bool _cargandoMas = false;
  String? _error;
  String _filtroEstado = '';
  int _pagina = 1;
  int _totalPaginas = 1;
  List<OrderModel> _pedidos = [];
  int? _pedidoExpandido;

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  Future<void> _cargarPedidos({bool reiniciar = true}) async {
    if (reiniciar) {
      setState(() {
        _cargando = true;
        _pagina = 1;
        _error = null;
      });
    } else {
      setState(() => _cargandoMas = true);
    }

    try {
      final res = await OrderService.instance.listarPedidos(
        pagina: _pagina,
        estado: _filtroEstado,
      );

      if (mounted) {
        setState(() {
          _pedidos = reiniciar ? res.lista : [..._pedidos, ...res.lista];
          _totalPaginas = res.totalPaginas;
          _cargando = false;
          _cargandoMas = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudieron sincronizar los pedidos.';
          _cargando = false;
          _cargandoMas = false;
        });
      }
    }
  }

  Future<void> _pagarAhora(OrderModel pedido) async {
    try {
      final checkout = await WompiService.instance.reanudarCheckout(pedido.referencia);
      final cliente = {
        'nombre': pedido.clienteNombre,
        'correo': pedido.clienteCorreo,
        'telefono': pedido.telefono,
        'ciudad': pedido.ciudad,
        'direccion': pedido.direccion,
      };

      if (!mounted) return;
      final outcome = await WompiCheckoutModal.iniciarPagoWompiModal(
        context,
        pedido: checkout,
        cliente: cliente,
        cancelarAlCerrar: false,
      );

      if (outcome.status == 'aprobado') {
        _cargarPedidos(reiniciar: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Pago completado con éxito!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No fue posible reanudar el proceso de pago.')),
            backgroundColor: FashionColors.statusDanger,
          ),
        );
      }
    }
  }

  Future<void> _cancelarPedido(OrderModel pedido) async {
    try {
      await WompiService.instance.cancelarCheckout(pedido.referencia);
      _cargarPedidos(reiniciar: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido cancelado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.obtenerMensajeError(e, 'No fue posible cancelar el pedido.')),
            backgroundColor: FashionColors.statusDanger,
          ),
        );
      }
    }
  }

  Future<void> _recomprar(OrderModel pedido) async {
    int agregados = 0;
    for (final it in pedido.detalles) {
      if (it.productoId != null) {
        final prod = await ProductService.instance.obtenerProducto(it.productoId!);
        if (prod != null) {
          final variante = prod.variantes.where((v) => v.idVariante == it.varianteId).firstOrNull;
          if (variante != null && variante.stock > 0) {
            ref.read(cartProvider.notifier).agregarPrenda(prod, variante, it.cantidad);
            agregados++;
          }
        }
      }
    }

    if (mounted) {
      if (agregados > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se agregaron $agregados prendas disponibles a tu bolsa.'),
            action: SnackBarAction(
              label: 'Ir a bolsa',
              textColor: FashionColors.brandAccent,
              onPressed: () => context.go('/carrito'),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Las prendas de este pedido no tienen stock disponible actualmente.')),
        );
      }
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'Pagado':
      case 'Entregado':
        return FashionColors.statusSuccess;
      case 'En_Preparacion':
      case 'Enviado':
        return FashionColors.atelierJade;
      case 'Pendiente_Pago':
      case 'Revision_Pago':
        return FashionColors.statusWarning;
      case 'Cancelado':
      case 'Rechazado':
      case 'Expirado':
      default:
        return FashionColors.statusDanger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final estados = [
      {'val': '', 'label': 'Todos'},
      {'val': 'Pendiente_Pago', 'label': 'Pendiente'},
      {'val': 'Pagado', 'label': 'Pagado'},
      {'val': 'En_Preparacion', 'label': 'En preparación'},
      {'val': 'Enviado', 'label': 'Enviado'},
      {'val': 'Entregado', 'label': 'Entregado'},
    ];

    return Column(
      children: [
        // CHIPS DE FILTRO POR ESTADO
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: estados.map((e) {
              final sel = _filtroEstado == e['val'];
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(e['label']!),
                  selected: sel,
                  selectedColor: FashionColors.inkPrimary,
                  backgroundColor: FashionColors.surfaceCard,
                  side: BorderSide(color: sel ? FashionColors.inkPrimary : FashionColors.borderSubtle),
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: sel ? Colors.white : FashionColors.inkPrimary,
                  ),
                  onSelected: (_) {
                    setState(() => _filtroEstado = e['val']!);
                    _cargarPedidos(reiniciar: true);
                  },
                ),
              );
            }).toList(),
          ),
        ),

        // LISTA DE PEDIDOS O ESTADOS
        Expanded(
          child: _cargando
              ? const Center(child: CircularProgressIndicator(color: FashionColors.inkPrimary))
              : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: GoogleFonts.plusJakartaSans(color: FashionColors.inkPrimary),
                      ),
                    )
                  : _pedidos.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const AtelierEmptyStateIllustration(
                                  type: AtelierEmptyStateType.emptyBag,
                                  size: 110,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No tienes pedidos registrados en este estado.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), // Clearance para Floating Pill Dock
                          itemCount: _pedidos.length + (_pagina < _totalPaginas ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _pedidos.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Center(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: FashionColors.surfaceMuted,
                                      foregroundColor: FashionColors.inkPrimary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: _cargandoMas
                                        ? null
                                        : () {
                                            _pagina++;
                                            _cargarPedidos(reiniciar: false);
                                          },
                                    child: _cargandoMas
                                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                        : const Text('Cargar más pedidos'),
                                  ),
                                ),
                              );
                            }

                            final pedido = _pedidos[index];
                            final expandido = _pedidoExpandido == pedido.id;
                            final esOnline = pedido.referencia.startsWith('FS-') && !pedido.referencia.startsWith('FS-PED-');

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: FashionColors.surfaceCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: FashionColors.borderSubtle),
                              ),
                              child: Column(
                                children: [
                                  // Encabezado del pedido
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    onTap: () => setState(() => _pedidoExpandido = expandido ? null : pedido.id),
                                    title: Row(
                                      children: [
                                        Text(
                                          pedido.referencia,
                                          style: GoogleFonts.jetBrainsMono(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: FashionColors.inkPrimary,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _colorEstado(pedido.estado).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            OrderService.estadosPedido[pedido.estado] ?? pedido.estado,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: _colorEstado(pedido.estado),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        '${pedido.fechaPedido} · Total: ${CurrencyFormatter.formatearCOP(pedido.total)}',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: FashionColors.inkSecondary),
                                      ),
                                    ),
                                    trailing: Icon(
                                      expandido ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                      color: FashionColors.inkPrimary,
                                    ),
                                  ),

                                  // Detalle expandible
                                  if (expandido) ...[
                                    const Divider(height: 1, color: FashionColors.borderSubtle),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Ítems de la orden
                                          ...pedido.detalles.map((it) => Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        '${it.nombre} (${it.talla}) x${it.cantidad}',
                                                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: FashionColors.inkPrimary),
                                                      ),
                                                    ),
                                                    Text(
                                                      CurrencyFormatter.formatearCOP(it.subtotal),
                                                      style: FashionTheme.priceTextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                                    ),
                                                  ],
                                                ),
                                              )),

                                          const SizedBox(height: 12),
                                          if (pedido.numeroGuia.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: FashionColors.surfaceMuted,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.local_shipping_outlined, size: 16, color: FashionColors.brandAccent),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Guía: ${pedido.numeroGuia} (${pedido.empresaTransportadora})',
                                                    style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
                                                  ),
                                                ],
                                              ),
                                            ),

                                          const SizedBox(height: 14),
                                          // Acciones de pago o recompra
                                          Row(
                                            children: [
                                              if (pedido.estado == 'Pendiente_Pago' && esOnline) ...[
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: FashionColors.brandAccent,
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                  onPressed: () => _pagarAhora(pedido),
                                                  child: const Text('Pagar ahora', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                ),
                                                const SizedBox(width: 8),
                                                OutlinedButton(
                                                  style: OutlinedButton.styleFrom(
                                                    side: const BorderSide(color: FashionColors.statusDanger),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  ),
                                                  onPressed: () => _cancelarPedido(pedido),
                                                  child: const Text('Cancelar', style: TextStyle(fontSize: 12, color: FashionColors.statusDanger)),
                                                ),
                                              ],
                                              const Spacer(),
                                              TextButton.icon(
                                                style: TextButton.styleFrom(foregroundColor: FashionColors.inkPrimary),
                                                onPressed: () => _recomprar(pedido),
                                                icon: const Icon(Icons.replay_rounded, size: 16),
                                                label: Text(
                                                  'Volver a comprar',
                                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
