// @source-mirror: src/views/admin/VistaMensajesContacto.vue, app/Http/Controllers/api/ContactoController.php
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/data/services/contact_service.dart';
import 'package:fashion_style_mobile/presentation/layouts/admin_shell_layout.dart';

class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen> {
  bool _cargando = true;
  List<Map<String, dynamic>> _mensajes = [];
  int _nuevos = 0;
  int _pagina = 1;
  int _totalPaginas = 1;
  int _totalRegistros = 0;

  String _filtroEstado = '';
  final String _filtroTipo = '';
  final TextEditingController _buscarCtrl = TextEditingController();

  static const Map<String, String> _tiposMap = {
    'peticion': 'Petición',
    'queja': 'Queja',
    'reclamo': 'Reclamo',
    'sugerencia': 'Sugerencia',
    'felicitacion': 'Felicitación',
    'consulta': 'Consulta',
  };

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar({bool silencioso = false}) async {
    if (!silencioso) setState(() => _cargando = true);
    try {
      final res = await ContactService.instance.listarMensajes(
        pagina: _pagina,
        estado: _filtroEstado.isNotEmpty ? _filtroEstado : null,
        tipo: _filtroTipo.isNotEmpty ? _filtroTipo : null,
        buscar: _buscarCtrl.text.trim().isNotEmpty ? _buscarCtrl.text.trim() : null,
      );

      if (mounted) {
        setState(() {
          _mensajes = (res['mensajes'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? [];
          _totalPaginas = res['totalPaginas'] as int? ?? 1;
          _totalRegistros = res['totalRegistros'] as int? ?? _mensajes.length;
          _nuevos = res['nuevos'] as int? ?? 0;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.obtenerMensajeError(e, 'No se pudieron cargar los mensajes.'))),
        );
      }
    }
  }

  Color _obtenerColorEstado(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'nuevo':
        return FashionColors.brandAccent;
      case 'leido':
        return FashionColors.slateAccent;
      case 'respondido':
        return FashionColors.verdeExito;
      default:
        return FashionColors.inkSecondary;
    }
  }

  String _formatearFecha(dynamic rawFecha) {
    if (rawFecha == null) return '—';
    try {
      final dt = DateTime.parse(rawFecha.toString()).toLocal();
      final mes = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'][dt.month - 1];
      final hora = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} $mes ${dt.year}, $hora:$min';
    } catch (_) {
      return rawFecha.toString();
    }
  }

  void _abrirDetalleMensaje(Map<String, dynamic> mensaje) {
    final id = mensaje['id'] is int ? mensaje['id'] as int : int.tryParse(mensaje['id'].toString()) ?? 0;
    final estado = mensaje['estado']?.toString() ?? 'nuevo';

    // Si es nuevo, marcar como leído de inmediato
    if (estado == 'nuevo' && id > 0) {
      ContactService.instance.cambiarEstado(id, 'leido').catchError((_) {});
      setState(() {
        mensaje['estado'] = 'leido';
        if (_nuevos > 0) _nuevos -= 1;
      });
    }

    final respuestaCtrl = TextEditingController();
    bool enviando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final respuestas = (mensaje['respuestas'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? [];

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              decoration: const BoxDecoration(
                color: FashionColors.surfaceCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: FashionColors.borderSubtle, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Header del mensaje
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: FashionColors.inkPrimary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            mensaje['radicado']?.toString() ?? 'PQRS',
                            style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _obtenerColorEstado(mensaje['estado']).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            (mensaje['estado']?.toString() ?? 'NUEVO').toUpperCase(),
                            style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w700, color: _obtenerColorEstado(mensaje['estado'])),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20, color: FashionColors.inkSecondary),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Datos del cliente
                    Text(
                      '${mensaje['nombre'] ?? ''} ${mensaje['apellidos'] ?? ''}'.trim(),
                      style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Correo: ${mensaje['correo'] ?? '—'} · Tel: ${mensaje['telefono'] ?? '—'}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: FashionColors.inkSecondary),
                    ),
                    if (mensaje['ciudad'] != null && mensaje['ciudad'].toString().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Ubicación: ${mensaje['ciudad']}, ${mensaje['pais'] ?? 'Colombia'} · Doc: ${mensaje['tipo_documento'] ?? ''} ${mensaje['numero_documento'] ?? ''}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FashionColors.inkSecondary),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Contenido del mensaje del cliente
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: FashionColors.canvasBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: FashionColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _tiposMap[mensaje['tipo_comunicacion']] ?? (mensaje['tipo_comunicacion']?.toString().toUpperCase() ?? 'SOLICITUD'),
                                style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: FashionColors.slateAccent),
                              ),
                              Text(
                                _formatearFecha(mensaje['created_at']),
                                style: GoogleFonts.jetBrainsMono(fontSize: 10, color: FashionColors.inkSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mensaje['mensaje']?.toString() ?? '',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.45, color: FashionColors.inkPrimary),
                          ),
                        ],
                      ),
                    ),

                    // Historial de respuestas anteriores
                    if (respuestas.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Respuestas enviadas (${respuestas.length}):',
                        style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
                      ),
                      const SizedBox(height: 6),
                      ...respuestas.map((r) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Operador: ${r['usuario']?['nombre'] ?? 'Personal FashionStyle'}',
                                    style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF166534)),
                                  ),
                                  Text(
                                    _formatearFecha(r['created_at']),
                                    style: GoogleFonts.jetBrainsMono(fontSize: 9, color: const Color(0xFF166534)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                r['mensaje']?.toString() ?? '',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF14532D)),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 16),
                    Text(
                      'Redactar respuesta al cliente:',
                      style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: respuestaCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Escribe tu respuesta aquí. Se enviará directamente al correo del cliente.',
                        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: FashionColors.inkSecondary),
                        filled: true,
                        fillColor: FashionColors.canvasBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FashionColors.borderSubtle)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FashionColors.borderSubtle)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FashionColors.inkPrimary)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FashionColors.inkPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: enviando
                            ? null
                            : () async {
                                final texto = respuestaCtrl.text.trim();
                                if (texto.length < 5) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(content: Text('La respuesta debe tener al menos 5 caracteres.')),
                                  );
                                  return;
                                }

                                setModalState(() => enviando = true);
                                try {
                                  final res = await ContactService.instance.responderMensaje(id, texto);
                                  Navigator.pop(sheetCtx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(res['message']?.toString() ?? 'Respuesta enviada al cliente.')),
                                  );
                                  _cargar(silencioso: true);
                                } catch (e) {
                                  setModalState(() => enviando = false);
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text(ApiClient.obtenerMensajeError(e, 'No se pudo enviar la respuesta.'))),
                                  );
                                }
                              },
                        icon: enviando
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send_rounded, size: 16),
                        label: Text(
                          enviando ? 'Enviando correo...' : 'Enviar Respuesta al Correo',
                          style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminShellLayout(
      currentPath: '/admin/mensajes',
      child: Column(
        children: [
          // Header y búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: FashionColors.surfaceCard,
              border: Border(bottom: BorderSide(color: FashionColors.borderSubtle)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mensajes y PQRS',
                          style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
                        ),
                        Text(
                          '$_nuevos sin leer · $_totalRegistros registros (pág. $_pagina/$_totalPaginas)',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FashionColors.inkSecondary),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20, color: FashionColors.inkPrimary),
                      onPressed: () => _cargar(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Barra de búsqueda
                TextField(
                  controller: _buscarCtrl,
                  onSubmitted: (_) {
                    setState(() => _pagina = 1);
                    _cargar();
                  },
                  decoration: InputDecoration(
                    hintText: 'Radicado, nombre, correo...',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: FashionColors.inkSecondary.withValues(alpha: 0.6)),
                    prefixIcon: const Icon(Icons.search, size: 18, color: FashionColors.inkSecondary),
                    suffixIcon: _buscarCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _buscarCtrl.clear();
                              setState(() => _pagina = 1);
                              _cargar();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: FashionColors.canvasBackground,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FashionColors.borderSubtle)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FashionColors.borderSubtle)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FashionColors.inkPrimary)),
                  ),
                ),
                const SizedBox(height: 10),

                // Chips de filtro de estado
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFiltroChip('Todos', ''),
                      const SizedBox(width: 6),
                      _buildFiltroChip('Nuevos', 'nuevo', badge: _nuevos > 0 ? '$_nuevos' : null),
                      const SizedBox(width: 6),
                      _buildFiltroChip('Leídos', 'leido'),
                      const SizedBox(width: 6),
                      _buildFiltroChip('Respondidos', 'respondido'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de mensajes
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: FashionColors.inkPrimary))
                : _mensajes.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(32),
                          children: [
                            const SizedBox(height: 48),
                            Icon(Icons.mail_outline, size: 48, color: FashionColors.inkSecondary.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'No hay mensajes para mostrar.',
                                style: GoogleFonts.plusJakartaSans(color: FashionColors.inkSecondary, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _cargar,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 96),
                          itemCount: _mensajes.length,
                          itemBuilder: (context, index) {
                            final m = _mensajes[index];
                            final estado = m['estado']?.toString() ?? 'nuevo';
                            final colorEstado = _obtenerColorEstado(estado);
                            final tipo = _tiposMap[m['tipo_comunicacion']] ?? m['tipo_comunicacion']?.toString() ?? 'PQRS';

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: estado == 'nuevo' ? FashionColors.brandAccent.withValues(alpha: 0.4) : FashionColors.borderSubtle,
                                  width: estado == 'nuevo' ? 1.5 : 1,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _abrirDetalleMensaje(m),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: FashionColors.inkPrimary.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              m['radicado']?.toString() ?? 'PQRS',
                                              style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: colorEstado.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              estado.toUpperCase(),
                                              style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w700, color: colorEstado),
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            _formatearFecha(m['created_at']),
                                            style: GoogleFonts.jetBrainsMono(fontSize: 10, color: FashionColors.inkSecondary),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${m['nombre'] ?? ''} ${m['apellidos'] ?? ''}'.trim(),
                                              style: GoogleFonts.spaceGrotesk(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: FashionColors.inkPrimary,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: FashionColors.canvasBackground,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: FashionColors.borderSubtle),
                                            ),
                                            child: Text(
                                              tipo,
                                              style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w600, color: FashionColors.inkSecondary),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        m['correo']?.toString() ?? '',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FashionColors.inkSecondary),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        m['mensaje']?.toString() ?? '',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: FashionColors.inkPrimary),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String etiqueta, String valor, {String? badge}) {
    final seleccionado = _filtroEstado == valor;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          _filtroEstado = valor;
          _pagina = 1;
        });
        _cargar();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: seleccionado ? FashionColors.inkPrimary : FashionColors.canvasBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: seleccionado ? FashionColors.inkPrimary : FashionColors.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              etiqueta,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: seleccionado ? Colors.white : FashionColors.inkSecondary,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: seleccionado ? FashionColors.brandAccent : FashionColors.brandAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
