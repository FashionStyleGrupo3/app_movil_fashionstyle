// @source-mirror: src/views/publico/VistaMiPerfil.vue, src/components/perfil/SeccionMisPedidos.vue, src/components/perfil/SeccionFavoritos.vue
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fashion_style_mobile/core/constants/invoice_constants.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/core/utils/audit_text_formatter.dart';
import 'package:fashion_style_mobile/core/utils/currency_formatter.dart';
import 'package:fashion_style_mobile/core/validators/garment_and_field_validators.dart';
import 'package:fashion_style_mobile/core/validators/password_validator.dart';
import 'package:fashion_style_mobile/data/models/audit/audit_models.dart';
import 'package:fashion_style_mobile/data/models/cart/cart_item.dart';
import 'package:fashion_style_mobile/data/models/invoice/invoice_item_detail.dart';
import 'package:fashion_style_mobile/data/models/invoice/invoice_model.dart';
import 'package:fashion_style_mobile/data/models/order/order_item_detail.dart';
import 'package:fashion_style_mobile/data/models/order/order_model.dart';
import 'package:fashion_style_mobile/data/models/order/order_status.dart';
import 'package:fashion_style_mobile/data/models/payment/wompi_checkout_data.dart';
import 'package:fashion_style_mobile/data/models/product/catalog.dart';
import 'package:fashion_style_mobile/data/models/product/category.dart';
import 'package:fashion_style_mobile/data/models/product/price_info.dart';
import 'package:fashion_style_mobile/data/models/product/product.dart';
import 'package:fashion_style_mobile/data/models/product/product_filters.dart';
import 'package:fashion_style_mobile/data/models/product/product_image.dart';
import 'package:fashion_style_mobile/data/models/product/product_variant.dart';
import 'package:fashion_style_mobile/data/models/product/promotion.dart';
import 'package:fashion_style_mobile/data/services/invoice_service.dart';
import 'package:fashion_style_mobile/data/services/order_service.dart';
import 'package:fashion_style_mobile/data/services/product_service.dart';
import 'package:fashion_style_mobile/data/services/promotion_service.dart';
import 'package:fashion_style_mobile/data/services/security_service.dart';
import 'package:fashion_style_mobile/data/services/user_service.dart';
import 'package:fashion_style_mobile/data/services/wompi_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/public_shell_layout.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_state.dart';
import 'package:fashion_style_mobile/presentation/providers/cart_provider.dart';
import 'package:fashion_style_mobile/presentation/providers/favorites_provider.dart';
import 'package:fashion_style_mobile/presentation/screens/publico/profile_screen.dart';
import 'package:fashion_style_mobile/presentation/widgets/profile/favorites_section.dart';
import 'package:fashion_style_mobile/presentation/widgets/profile/my_data_section.dart';
import 'package:fashion_style_mobile/presentation/widgets/store/product_card.dart';
import 'package:fashion_style_mobile/presentation/widgets/store/size_guide_modal.dart';
import 'package:fashion_style_mobile/presentation/widgets/store/cart_drawer.dart';
import 'package:fashion_style_mobile/presentation/widgets/payment/wompi_checkout_modal.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class SeccionMisPedidos extends ConsumerStatefulWidget {
  const SeccionMisPedidos();

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
          _error = 'No se pudieron cargar los pedidos.';
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
          SnackBar(content: Text('No se pudo reanudar el pago: $e'), backgroundColor: FashionColors.peligro),
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
          SnackBar(content: Text('Error al cancelar: $e'), backgroundColor: FashionColors.peligro),
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
        return FashionColors.verdeExito;
      case 'En_Preparacion':
      case 'Enviado':
        return FashionColors.azulInfo;
      case 'Pendiente_Pago':
      case 'Revision_Pago':
        return FashionColors.aviso;
      case 'Cancelado':
      case 'Rechazado':
      case 'Expirado':
      default:
        return FashionColors.peligro;
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: estados.map((e) {
              final sel = _filtroEstado == e['val'];
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(e['label']!),
                  selected: sel,
                  selectedColor: FashionColors.negroElegante,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                    color: sel ? Colors.white : FashionColors.textoOscuro,
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
              ? const Center(child: CircularProgressIndicator(color: FashionColors.rosaCorporativo))
              : _error != null
                  ? Center(child: Text(_error!))
                  : _pedidos.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'No tienes pedidos registrados en este estado.',
                              style: TextStyle(color: FashionColors.textoMuted),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _pedidos.length + (_pagina < _totalPaginas ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _pedidos.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Center(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: FashionColors.fondoClaro, foregroundColor: FashionColors.textoOscuro),
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
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: FashionColors.grisBorde),
                              ),
                              child: Column(
                                children: [
                                  // Encabezado del pedido
                                  ListTile(
                                    onTap: () => setState(() => _pedidoExpandido = expandido ? null : pedido.id),
                                    title: Row(
                                      children: [
                                        Text(
                                          pedido.referencia,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: _colorEstado(pedido.estado),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      '${pedido.fechaPedido} · Total: ${CurrencyFormatter.formatearCOP(pedido.total)}',
                                      style: const TextStyle(fontSize: 12, color: FashionColors.textoMuted),
                                    ),
                                    trailing: Icon(expandido ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                                  ),

                                  // Detalle expandible
                                  if (expandido) ...[
                                    const Divider(height: 1),
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
                                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                                      ),
                                                    ),
                                                    Text(
                                                      CurrencyFormatter.formatearCOP(it.subtotal),
                                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                              )),

                                          const SizedBox(height: 12),
                                          if (pedido.numeroGuia.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(color: FashionColors.fondoClaro, borderRadius: BorderRadius.circular(6)),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.local_shipping, size: 16, color: FashionColors.rosaOscuro),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    'Guía: ${pedido.numeroGuia} (${pedido.empresaTransportadora})',
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),

                                          const SizedBox(height: 12),
                                          // Acciones de pago o recompra
                                          Row(
                                            children: [
                                              if (pedido.estado == 'Pendiente_Pago' && esOnline) ...[
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: FashionColors.negroElegante, foregroundColor: Colors.white),
                                                  onPressed: () => _pagarAhora(pedido),
                                                  child: const Text('Pagar ahora', style: TextStyle(fontSize: 12)),
                                                ),
                                                const SizedBox(width: 8),
                                                OutlinedButton(
                                                  onPressed: () => _cancelarPedido(pedido),
                                                  child: const Text('Cancelar', style: TextStyle(fontSize: 12, color: FashionColors.peligro)),
                                                ),
                                              ],
                                              const Spacer(),
                                              TextButton.icon(
                                                onPressed: () => _recomprar(pedido),
                                                icon: const Icon(Icons.replay, size: 16),
                                                label: const Text('Volver a comprar', style: TextStyle(fontSize: 12)),
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

// ============================================================================
// 3. SECCIÓN FAVORITOS (SeccionFavoritos.vue)
// ============================================================================
