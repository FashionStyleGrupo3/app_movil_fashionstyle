// @source-mirror: src/services/ventaServicio.js, src/services/pagoServicio.js
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';

class BankAccountConfig {
  final int id;
  final String banco;
  final String tipoCuenta;
  final String numeroCuenta;
  final String titular;
  final String concepto;
  final double porcentaje;
  final bool activa;
  final double? montoAsignado;

  String get tipo => tipoCuenta;

  const BankAccountConfig({
    required this.id,
    required this.banco,
    required this.tipoCuenta,
    required this.numeroCuenta,
    required this.titular,
    required this.concepto,
    required this.porcentaje,
    required this.activa,
    this.montoAsignado,
  });

  factory BankAccountConfig.fromJson(Map<String, dynamic> map) {
    return BankAccountConfig(
      id: JsonParser.toInt(map['id']),
      banco: JsonParser.toStr(map['banco']),
      tipoCuenta: JsonParser.toStr(map['tipo_cuenta'] ?? map['tipoCuenta']),
      numeroCuenta: JsonParser.toStr(map['numero_cuenta'] ?? map['numeroCuenta']),
      titular: JsonParser.toStr(map['titular']),
      concepto: JsonParser.toStr(map['concepto']),
      porcentaje: JsonParser.toDouble(map['porcentaje']),
      activa: map['activa'] == null ? true : JsonParser.toBool(map['activa']),
      montoAsignado: map['monto_asignado'] != null ? JsonParser.toDouble(map['monto_asignado']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'banco': banco,
      'tipo_cuenta': tipoCuenta,
      'numero_cuenta': numeroCuenta,
      'titular': titular,
      'concepto': concepto,
      'porcentaje': porcentaje,
      'activa': activa,
      if (montoAsignado != null) 'monto_asignado': montoAsignado,
    };
  }

  BankAccountConfig copyWith({double? montoAsignado}) {
    return BankAccountConfig(
      id: id,
      banco: banco,
      tipoCuenta: tipoCuenta,
      numeroCuenta: numeroCuenta,
      titular: titular,
      concepto: concepto,
      porcentaje: porcentaje,
      activa: activa,
      montoAsignado: montoAsignado ?? this.montoAsignado,
    );
  }
}
