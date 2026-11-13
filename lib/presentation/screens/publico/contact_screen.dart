// @source-mirror: src/views/publico/VistaContacto.vue, app/Http/Controllers/api/ContactoController.php
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/theme/fashion_theme.dart';
import 'package:fashion_style_mobile/data/services/contact_service.dart';
import 'package:fashion_style_mobile/presentation/providers/auth_provider.dart';

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Formulario radicación
  final _formKey = GlobalKey<FormState>();
  String _tipoComunicacion = 'peticion';
  final _nombreCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  String _tipoDocumento = 'CC';
  final _numeroDocumentoCtrl = TextEditingController();
  String _pais = 'Colombia';
  final _ciudadCtrl = TextEditingController(text: 'Bogotá D.C.');
  final _telefonoCtrl = TextEditingController();
  final _telefonoFijoCtrl = TextEditingController();
  final _mensajeCtrl = TextEditingController();
  bool _enviando = false;

  // Consulta por radicado
  final _consultaRadicadoCtrl = TextEditingController();
  final _consultaCorreoCtrl = TextEditingController();
  bool _consultando = false;
  Map<String, dynamic>? _resultadoConsulta;
  String? _errorConsulta;

  static const List<Map<String, String>> _tiposComunicacion = [
    {'valor': 'peticion', 'etiqueta': 'Petición'},
    {'valor': 'queja', 'etiqueta': 'Queja'},
    {'valor': 'reclamo', 'etiqueta': 'Reclamo'},
    {'valor': 'sugerencia', 'etiqueta': 'Sugerencia'},
    {'valor': 'felicitacion', 'etiqueta': 'Felicitación'},
    {'valor': 'consulta', 'etiqueta': 'Consulta'},
  ];

  static const List<Map<String, String>> _tiposDocumento = [
    {'valor': 'CC', 'etiqueta': 'Cédula de ciudadanía'},
    {'valor': 'CE', 'etiqueta': 'Cédula de extranjería'},
    {'valor': 'TI', 'etiqueta': 'Tarjeta de identidad'},
    {'valor': 'NIT', 'etiqueta': 'NIT'},
    {'valor': 'PP', 'etiqueta': 'Pasaporte'},
  ];

  static const List<String> _paises = [
    'Colombia',
    'Argentina',
    'Chile',
    'Ecuador',
    'España',
    'Estados Unidos',
    'México',
    'Panamá',
    'Perú',
    'Venezuela',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (auth.estaAutenticado && auth.usuario != null) {
        final u = auth.usuario!;
        final nombreCompleto = auth.nombreUsuario;
        final partes = nombreCompleto.trim().split(RegExp(r'\s+'));
        if (partes.isNotEmpty) {
          _nombreCtrl.text = partes.first;
          if (partes.length > 1) {
            _apellidosCtrl.text = partes.sublist(1).join(' ');
          }
        }
        final correo = auth.correoUsuario;
        _correoCtrl.text = correo;
        _consultaCorreoCtrl.text = correo;

        final tel = u['telefono']?.toString();
        if (tel != null && tel.isNotEmpty) {
          _telefonoCtrl.text = tel.replaceAll(RegExp(r'\D'), '');
        }
        final ciudad = u['ciudad']?.toString();
        if (ciudad != null && ciudad.isNotEmpty) {
          _ciudadCtrl.text = ciudad;
        }
        final numDoc = (u['numero_documento'] ?? u['documento'])?.toString();
        if (numDoc != null && numDoc.isNotEmpty) {
          _numeroDocumentoCtrl.text = numDoc;
        }
        final tipoDoc = (u['tipo_documento'])?.toString();
        if (tipoDoc != null && tipoDoc.isNotEmpty) {
          final td = tipoDoc.toUpperCase();
          if (_tiposDocumento.any((d) => d['valor'] == td)) {
            _tipoDocumento = td;
          }
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nombreCtrl.dispose();
    _apellidosCtrl.dispose();
    _correoCtrl.dispose();
    _numeroDocumentoCtrl.dispose();
    _ciudadCtrl.dispose();
    _telefonoCtrl.dispose();
    _telefonoFijoCtrl.dispose();
    _mensajeCtrl.dispose();
    _consultaRadicadoCtrl.dispose();
    _consultaCorreoCtrl.dispose();
    super.dispose();
  }

  Future<void> _radicar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);
    try {
      final payload = {
        'tipo_comunicacion': _tipoComunicacion,
        'nombre': _nombreCtrl.text.trim(),
        'apellidos': _apellidosCtrl.text.trim(),
        'correo': _correoCtrl.text.trim(),
        'tipo_documento': _tipoDocumento,
        'numero_documento': _numeroDocumentoCtrl.text.trim(),
        'pais': _pais,
        'ciudad': _pais == 'Colombia' ? _ciudadCtrl.text.trim() : (_ciudadCtrl.text.trim().isEmpty ? null : _ciudadCtrl.text.trim()),
        'telefono': _telefonoCtrl.text.trim(),
        if (_telefonoFijoCtrl.text.trim().isNotEmpty) 'telefono_fijo': _telefonoFijoCtrl.text.trim(),
        'mensaje': _mensajeCtrl.text.trim(),
      };

      final res = await ContactService.instance.radicarMensaje(payload);
      final radicado = res['data']?['radicado']?.toString() ?? res['radicado']?.toString() ?? 'PQRS';

      if (!mounted) return;
      setState(() => _enviando = false);

      _mensajeCtrl.clear();
      _mostrarDialogoExitoRadicado(radicado);
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.obtenerMensajeError(e, 'No se pudo radicar la solicitud.'))),
        );
      }
    }
  }

  void _mostrarDialogoExitoRadicado(String radicado) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: FashionColors.verdeExito, size: 28),
            const SizedBox(width: 10),
            Text('¡Solicitud Radicada!', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hemos recibido tu mensaje correctamente. Nuestro equipo lo revisará y te responderá por correo.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FashionColors.canvasBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FashionColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NÚMERO DE RADICADO', style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w700, color: FashionColors.inkSecondary)),
                        const SizedBox(height: 2),
                        SelectableText(
                          radicado,
                          style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    tooltip: 'Copiar radicado',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: radicado));
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Radicado copiado al portapapeles')));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FashionColors.inkPrimary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _consultar() async {
    final radicado = _consultaRadicadoCtrl.text.trim();
    final correo = _consultaCorreoCtrl.text.trim();

    if (radicado.isEmpty || correo.isEmpty) {
      setState(() => _errorConsulta = 'Ingresa el número de radicado y tu correo.');
      return;
    }

    setState(() {
      _consultando = true;
      _errorConsulta = null;
      _resultadoConsulta = null;
    });

    try {
      final res = await ContactService.instance.consultarRadicado(radicado, correo);
      if (mounted) {
        setState(() {
          _resultadoConsulta = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : res;
          _consultando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorConsulta = ApiClient.obtenerMensajeError(e, 'No encontramos una solicitud con ese radicado y correo.');
          _consultando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FashionColors.canvasBackground,
      appBar: AppBar(
        title: Text(
          'Atención y PQRS',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 17, color: FashionColors.inkPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: FashionColors.borderSubtle)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: FashionColors.inkPrimary,
              unselectedLabelColor: FashionColors.inkSecondary,
              indicatorColor: FashionColors.inkPrimary,
              indicatorWeight: 2,
              labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(text: 'Radicar Solicitud'),
                Tab(text: 'Consultar Radicado'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _construirFormularioRadicacion(),
          _construirConsultaRadicado(),
        ],
      ),
    );
  }

  Widget _construirFormularioRadicacion() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera descriptiva
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FashionColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Formulario Oficial de Contacto',
                    style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Radica tu petición, queja, reclamo o sugerencia. Te responderemos directamente al correo registrado en un plazo máximo de 48 horas hábiles.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: FashionColors.inkSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Campos del formulario
            Text('Tipo de Solicitud *', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _tipoComunicacion,
              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
              items: _tiposComunicacion.map((t) => DropdownMenuItem(value: t['valor'], child: Text(t['etiqueta']!))).toList(),
              onChanged: (v) => setState(() => _tipoComunicacion = v ?? 'peticion'),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nombre *', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nombreCtrl,
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                        validator: (v) => (v == null || v.trim().length < 2) ? 'Escribe tu nombre' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Apellidos *', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _apellidosCtrl,
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                        validator: (v) => (v == null || v.trim().length < 2) ? 'Escribe tus apellidos' : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Text('Correo Electrónico (Para recibir la respuesta) *', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _correoCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresa tu correo electrónico';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) return 'Correo no válido';
                return null;
              },
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tipo Doc. *', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _tipoDocumento,
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                        items: _tiposDocumento.map((d) => DropdownMenuItem(value: d['valor'], child: Text(d['valor']!))).toList(),
                        onChanged: (v) => setState(() => _tipoDocumento = v ?? 'CC'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Número de Documento *', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _numeroDocumentoCtrl,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu documento' : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('País *', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _pais,
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                        items: _paises.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (v) => setState(() => _pais = v ?? 'Colombia'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ciudad *', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _ciudadCtrl,
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa la ciudad' : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Teléfono Móvil *', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _telefonoCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(hintText: '3001234567', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Ingresa tu celular';
                          if (_pais == 'Colombia' && !RegExp(r'^3\d{9}$').hasMatch(v.trim())) {
                            return '10 dígitos empezando por 3';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Teléfono Fijo', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _telefonoFijoCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(hintText: 'Opcional', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Text('Mensaje / Detalle de la Solicitud *', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _mensajeCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Cuéntanos en detalle tu solicitud (mínimo 10 caracteres)...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(14),
              ),
              validator: (v) => (v == null || v.trim().length < 10) ? 'Escribe al menos 10 caracteres' : null,
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FashionColors.inkPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _enviando ? null : _radicar,
                icon: _enviando
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  _enviando ? 'Radicando solicitud...' : 'Radicar Solicitud PQRS',
                  style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tarjeta de información física de la tienda
            _construirTarjetaTienda(),
          ],
        ),
      ),
    );
  }

  Widget _construirConsultaRadicado() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FashionColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consultar Estado de tu Radicado',
                  style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ingresa tu número de radicado y el correo que registraste para consultar las respuestas de nuestro equipo.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: FashionColors.inkSecondary, height: 1.4),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _consultaRadicadoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Número de Radicado (ej. PQRS-2026-000001)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _consultaCorreoCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico Registrado',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FashionColors.inkPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _consultando ? null : _consultar,
                    icon: _consultando
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.search, size: 16),
                    label: Text(
                      _consultando ? 'Consultando...' : 'Consultar Solicitud',
                      style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_errorConsulta != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: FashionColors.peligro, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorConsulta!, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: FashionColors.peligro)),
                  ),
                ],
              ),
            ),

          if (_resultadoConsulta != null) _construirResultadoConsulta(_resultadoConsulta!),

          const SizedBox(height: 24),
          _construirTarjetaTienda(),
        ],
      ),
    );
  }

  Widget _construirResultadoConsulta(Map<String, dynamic> r) {
    final estado = (r['estado']?.toString() ?? 'nuevo').toLowerCase();
    String estadoEtiqueta = 'RECIBIDA';
    Color estadoColor = FashionColors.brandAccent;
    if (estado == 'leido') {
      estadoEtiqueta = 'EN REVISIÓN';
      estadoColor = FashionColors.slateAccent;
    } else if (estado == 'respondido') {
      estadoEtiqueta = 'RESPONDIDA';
      estadoColor = FashionColors.verdeExito;
    }

    final respuestas = (r['respuestas'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FashionColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                r['radicado']?.toString() ?? 'PQRS',
                style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: estadoColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  estadoEtiqueta,
                  style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w700, color: estadoColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Mensaje Radicado:',
            style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            r['mensaje']?.toString() ?? '',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4, color: FashionColors.inkPrimary),
          ),
          const SizedBox(height: 14),

          if (respuestas.isNotEmpty) ...[
            Text(
              'Respuestas Oficiales:',
              style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
            ),
            const SizedBox(height: 6),
            ...respuestas.map((resp) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Text(
                  resp['mensaje']?.toString() ?? '',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF14532D)),
                ),
              );
            }),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FashionColors.canvasBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded, size: 16, color: FashionColors.inkSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tu solicitud está en turno de revisión por parte de nuestro equipo.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FashionColors.inkSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirTarjetaTienda() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FashionColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.store_mall_directory_outlined, size: 20, color: FashionColors.inkPrimary),
              const SizedBox(width: 8),
              Text(
                'FashionStyle Tienda Principal',
                style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w700, color: FashionColors.inkPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _itemDatoTienda(Icons.location_on_outlined, 'Carrera 7 # 72-41, Bogotá D.C., Colombia'),
          _itemDatoTienda(Icons.phone_outlined, '+57 300 000 0001 / (601) 745-9800'),
          _itemDatoTienda(Icons.mail_outline, 'soporte.fashionstyle@gmail.com'),
          _itemDatoTienda(Icons.access_time_outlined, 'Lunes a sábado, 9:00 a. m. – 7:00 p. m.'),
        ],
      ),
    );
  }

  Widget _itemDatoTienda(IconData icono, String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icono, size: 14, color: FashionColors.inkSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: FashionColors.inkSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
