// @source-mirror: src/services/ventaServicio.js, src/services/pagoServicio.js
import 'dart:convert';
import 'package:fashion_style_mobile/core/constants/payment_constants.dart';
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/data/models/payment/bank_account_config.dart';
import 'package:fashion_style_mobile/data/models/payment/parallel_payment_control.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentConfigService {
  static final PaymentConfigService _instance = PaymentConfigService._internal();
  static PaymentConfigService get instance => _instance;

  PaymentConfigService._internal();

  static const List<Map<String, dynamic>> cuentasPredeterminadas = [
    {
      'id': 1,
      'banco': 'Bancolombia',
      'tipo_cuenta': 'Ahorros',
      'numero_cuenta': '245-891024-11',
      'titular': 'Taller de confección & Operarios',
      'concepto': 'Mano de Obra y confección Textil',
      'porcentaje': 60.0,
      'activa': true,
    },
    {
      'id': 2,
      'banco': 'Bancolombia',
      'tipo_cuenta': 'Corriente',
      'numero_cuenta': '031-458920-55',
      'titular': 'FashionStyle S.A.S.',
      'concepto': 'Comercializacion y Operacion',
      'porcentaje': 25.0,
      'activa': true,
    },
    {
      'id': 3,
      'banco': 'Davivienda',
      'tipo_cuenta': 'Ahorros',
      'numero_cuenta': '008-921478-03',
      'titular': 'Fondo de Materia Prima e Insumos',
      'concepto': 'reposicion de Telas y Fornituras',
      'porcentaje': 15.0,
      'activa': true,
    },
  ];

  Future<Map<String, dynamic>> obtenerConfiguracionPasarela() async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString(claveStorageConfig);
    if (guardado == null) {
      return {
        'moneda': 'COP',
        'cuentas_bancarias': cuentasPredeterminadas.map((e) => BankAccountConfig.fromJson(e)).toList(),
      };
    }

    try {
      final parsed = jsonDecode(guardado) as Map<String, dynamic>;
      final rawCuentas = parsed['cuentas_bancarias'];
      List<BankAccountConfig> cuentas = [];
      if (rawCuentas is List) {
        cuentas = rawCuentas.whereType<Map<String, dynamic>>().map((e) => BankAccountConfig.fromJson(e)).toList();
      } else {
        cuentas = cuentasPredeterminadas.map((e) => BankAccountConfig.fromJson(e)).toList();
      }

      return {
        'moneda': JsonParser.toStr(parsed['moneda'], 'COP'),
        'cuentas_bancarias': cuentas,
      };
    } catch (_) {
      return {
        'moneda': 'COP',
        'cuentas_bancarias': cuentasPredeterminadas.map((e) => BankAccountConfig.fromJson(e)).toList(),
      };
    }
  }

  Future<void> guardarConfiguracionPasarela({
    String moneda = 'COP',
    required List<BankAccountConfig> cuentasBancarias,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'moneda': moneda,
      'cuentas_bancarias': cuentasBancarias.map((c) => c.toJson()).toList(),
    };
    await prefs.setString(claveStorageConfig, jsonEncode(map));
  }

  Future<List<BankAccountConfig>> obtenerCuentasDispersion() async {
    final conf = await obtenerConfiguracionPasarela();
    return (conf['cuentas_bancarias'] as List<BankAccountConfig>?) ?? [];
  }

  Map<String, dynamic> validarPorcentajesDispersion(List<BankAccountConfig> cuentas) {
    final total = cuentas.where((c) => c.activa).fold<double>(0.0, (acc, c) => acc + c.porcentaje);
    final valido = (total - 100.0).abs() < 0.01;
    return {
      'valido': valido,
      'mensaje': valido
          ? 'Válido'
          : 'La suma de porcentajes de cuentas activas debe ser exactamente 100% (actual: ${total.toStringAsFixed(1)}%)',
    };
  }

  List<BankAccountConfig> calcularDispersionFondos(
    double montoTotal,
    List<BankAccountConfig> cuentas,
  ) {
    final activas = cuentas.where((c) => c.activa).toList();
    return activas.map((c) {
      final valorAsignado = ((montoTotal * c.porcentaje) / 100).roundToDouble();
      return c.copyWith(montoAsignado: valorAsignado);
    }).toList();
  }

  Future<ParallelPaymentControl> obtenerControlParaleloPagos() async {
    final response = await ApiClient.instance.dio.get('/pagos/control-paralelo');
    final data = ApiResponseParser.extractData(response);
    return ParallelPaymentControl.fromJson(data is Map<String, dynamic> ? data : {});
  }
}
