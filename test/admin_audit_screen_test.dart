import 'package:flutter_test/flutter_test.dart';
import 'package:fashion_style_mobile/core/utils/audit_text_formatter.dart';

void main() {
  group('Pruebas unitarias defensivas de Bitácora de Auditoría (AuditTextFormatter)', () {
    test('1. Procesa evento de inicio de sesión con datos_nuevos sin datos_anteriores', () {
      final item = {
        'id': 15,
        'modelo': r'App\Models\User',
        'modelo_id': 1,
        'accion': 'INICIO_SESION',
        'usuario': {
          'id_usuario': 1,
          'nombre': 'Administrador FashionStyle',
          'correo': 'admin@fashionstyle.com',
        },
        'datos_anteriores': null,
        'datos_nuevos': {
          'via': 'password',
          'ultimo_acceso': '2026-11-12 23:46:56',
        },
        'ip': '190.12.34.56',
        'created_at': '2026-11-12T23:46:56.000000Z',
      };

      final desc = AuditTextFormatter.describirAuditoria(item);

      expect(desc.actor, 'Administrador FashionStyle');
      expect(desc.accion.etiqueta, 'Inicio de Sesión');
      expect(desc.datos.length, greaterThanOrEqualTo(1));
      expect(desc.cambios, isEmpty);
      expect(desc.soloInterno, isFalse);
    });

    test('2. Procesa evento de venta creada con montos, fechas y booleanos', () {
      final item = {
        'id': 11,
        'modelo': r'App\Models\Venta',
        'modelo_id': 4,
        'accion': 'created',
        'usuario': {
          'nombre': 'Administrador FashionStyle',
          'correo': 'admin@fashionstyle.com',
        },
        'datos_anteriores': null,
        'datos_nuevos': {
          'numero_comprobante': 'VO-FS-261112154058-R2GHYA',
          'pedido_id': 4,
          'usuario_id': 1,
          'descripcion': 'Venta online del pedido #4',
          'categoria': 'Venta Tienda Online',
          'notas': 'Pago Wompi ref: FS-261112154058-R2GHYA',
          'fecha_venta': '2026-11-12 15:41:37',
          'monto_total': '96000.00',
          'medio_pago': 'transferencia',
          'estado': 'Completada',
          'cancelada': false,
          'updated_at': '2026-11-12 15:41:37',
          'created_at': '2026-11-12 15:41:37',
          'id': 4,
        },
        'ip': '179.12.34.56',
        'created_at': '2026-11-12T15:41:37.000000Z',
      };

      final desc = AuditTextFormatter.describirAuditoria(item);

      expect(desc.modelo.clave, 'Venta');
      expect(desc.cambios, isEmpty);
      expect(desc.datos.any((d) => d.campo == 'monto_total'), isTrue);

      final datoMonto = desc.datos.firstWhere((d) => d.campo == 'monto_total');
      expect(datoMonto.valor.contains('96'), isTrue);
    });

    test('3. Procesa evento con usuario nulo (registro público / automático del sistema)', () {
      final item = {
        'id': 1,
        'modelo': r'App\Models\User',
        'modelo_id': 6,
        'accion': 'created',
        'usuario': null,
        'datos_anteriores': null,
        'datos_nuevos': {
          'nombre': 'Fashion Style',
          'correo': 'soporte.fashionstyle@gmail.com',
          'google_id': '117823066290757817994',
          'activo': true,
          'email_verified_at': '2026-11-12 15:15:14',
          'terminos_version': '1.0',
          'terminos_aceptados_at': '2026-11-12 15:15:14',
          'foto_perfil': 'https://lh3.googleusercontent.com/photo.jpg',
          'updated_at': '2026-11-12 15:15:14',
          'created_at': '2026-11-12 15:15:14',
          'id_usuario': 6,
        },
        'ip': '179.12.34.56',
        'created_at': '2026-11-12T15:15:14.000000Z',
      };

      final desc = AuditTextFormatter.describirAuditoria(item);
      final usuarioStr = AuditTextFormatter.formatearUsuario(item['usuario']);

      expect(usuarioStr, 'Sistema');
      expect(desc.actor, 'El sistema');
      expect(desc.datos.any((d) => d.campo == 'correo'), isTrue);
    });

    test('4. Procesa actualización de producto con comparativa antes -> después', () {
      final item = {
        'id': 9,
        'modelo': r'App\Models\Producto',
        'modelo_id': 1,
        'accion': 'updated',
        'usuario': {
          'nombre': 'Administrador FashionStyle',
        },
        'datos_anteriores': {
          'publicado': false,
        },
        'datos_nuevos': {
          'publicado': true,
        },
        'ip': '179.12.34.56',
        'created_at': '2026-11-12T15:40:00.000000Z',
      };

      final desc = AuditTextFormatter.describirAuditoria(item);

      expect(desc.cambios.length, 1);
      expect(desc.cambios.first.campo, 'publicado');
      expect(desc.cambios.first.antes, 'No');
      expect(desc.cambios.first.nuevo, 'Sí');
    });

    test('5. Formateador de fechas y etiquetas de día no lanzan excepciones con locales no inicializados', () {
      expect(() => AuditTextFormatter.formatearFecha('2026-11-12 15:41:37'), returnsNormally);
      expect(() => AuditTextFormatter.etiquetaDia('2026-11-12 15:41:37'), returnsNormally);
      expect(() => AuditTextFormatter.tiempoRelativo('2026-11-12 15:41:37'), returnsNormally);

      final fechaFmt = AuditTextFormatter.formatearFecha('2026-11-12 15:41:37');
      expect(fechaFmt.isNotEmpty, isTrue);
      expect(fechaFmt.contains('2026'), isTrue);
    });

    test('6. Soporta datos_anteriores y datos_nuevos serializados como cadenas JSON', () {
      final item = {
        'id': 88,
        'modelo': r'App\Models\Producto',
        'modelo_id': 2,
        'accion': 'updated',
        'usuario': {'nombre': 'Admin'},
        'datos_anteriores': '{"precio_venta": "50000", "color": "Azul"}',
        'datos_nuevos': '{"precio_venta": "65000", "color": "Rojo"}',
        'ip': '127.0.0.1',
      };

      final desc = AuditTextFormatter.describirAuditoria(item);
      expect(desc.cambios.length, 2);
      expect(desc.cambios.any((c) => c.campo == 'precio_venta'), isTrue);
      expect(desc.cambios.any((c) => c.campo == 'color'), isTrue);
    });
  });
}
