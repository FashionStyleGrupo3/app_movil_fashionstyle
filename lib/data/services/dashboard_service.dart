// @source-mirror: src/views/admin/VistaPanelControl.vue, src/components/admin/GraficoPanel.vue
import '../../core/network/api_client.dart';
import '../../core/network/api_response_parser.dart';

class DashboardKpis {
  final double ventasHoy;
  final double ventasMes;
  final int transaccionesMes;
  final int pedidosPendientes;
  final int ordenesActivas;
  final int stockTotal;
  final int alertasPendientes;

  const DashboardKpis({
    required this.ventasHoy,
    required this.ventasMes,
    required this.transaccionesMes,
    required this.pedidosPendientes,
    required this.ordenesActivas,
    required this.stockTotal,
    required this.alertasPendientes,
  });

  factory DashboardKpis.fromJson(Map<String, dynamic> json) {
    return DashboardKpis(
      ventasHoy: JsonParser.toDouble(json['ventas_hoy']),
      ventasMes: JsonParser.toDouble(json['ventas_mes']),
      transaccionesMes: JsonParser.toInt(json['transacciones_mes']),
      pedidosPendientes: JsonParser.toInt(json['pedidos_pendientes']),
      ordenesActivas: JsonParser.toInt(json['ordenes_activas']),
      stockTotal: JsonParser.toInt(json['stock_total']),
      alertasPendientes: JsonParser.toInt(json['alertas_pendientes']),
    );
  }

  factory DashboardKpis.empty() {
    return const DashboardKpis(
      ventasHoy: 0.0,
      ventasMes: 0.0,
      transaccionesMes: 0,
      pedidosPendientes: 0,
      ordenesActivas: 0,
      stockTotal: 0,
      alertasPendientes: 0,
    );
  }
}

class VentasPorMesItem {
  final String mes;
  final double pos;
  final double web;
  final int cantidad;

  const VentasPorMesItem({
    required this.mes,
    required this.pos,
    required this.web,
    required this.cantidad,
  });

  double get total => pos + web;

  factory VentasPorMesItem.fromJson(Map<String, dynamic> json) {
    return VentasPorMesItem(
      mes: JsonParser.toStr(json['mes']),
      pos: JsonParser.toDouble(json['pos']),
      web: JsonParser.toDouble(json['web']),
      cantidad: JsonParser.toInt(json['cantidad']),
    );
  }
}

class VentasPorMedioItem {
  final String medio;
  final double monto;

  const VentasPorMedioItem({
    required this.medio,
    required this.monto,
  });

  factory VentasPorMedioItem.fromJson(Map<String, dynamic> json) {
    return VentasPorMedioItem(
      medio: JsonParser.toStr(json['medio'], 'Sin dato'),
      monto: JsonParser.toDouble(json['monto']),
    );
  }
}

class ProduccionPorMesItem {
  final String mes;
  final int planificadas;
  final int completadas;

  const ProduccionPorMesItem({
    required this.mes,
    required this.planificadas,
    required this.completadas,
  });

  factory ProduccionPorMesItem.fromJson(Map<String, dynamic> json) {
    return ProduccionPorMesItem(
      mes: JsonParser.toStr(json['mes']),
      planificadas: JsonParser.toInt(json['planificadas']),
      completadas: JsonParser.toInt(json['completadas']),
    );
  }
}

class InventarioMenorStockItem {
  final String producto;
  final String talla;
  final int stock;

  const InventarioMenorStockItem({
    required this.producto,
    required this.talla,
    required this.stock,
  });

  factory InventarioMenorStockItem.fromJson(Map<String, dynamic> json) {
    return InventarioMenorStockItem(
      producto: JsonParser.toStr(json['producto'], 'Prenda'),
      talla: JsonParser.toStr(json['talla'], '-'),
      stock: JsonParser.toInt(json['stock']),
    );
  }
}

class InventarioDashboardData {
  final Map<String, int> alertasPorNivel;
  final List<InventarioMenorStockItem> menorStock;
  final int materiasBajoMinimo;
  final int movimientosMes;

  const InventarioDashboardData({
    required this.alertasPorNivel,
    required this.menorStock,
    required this.materiasBajoMinimo,
    required this.movimientosMes,
  });

  factory InventarioDashboardData.fromJson(Map<String, dynamic> json) {
    final rawAlertas = json['alertas_por_nivel'];
    final Map<String, int> alertas = {};
    if (rawAlertas is Map) {
      rawAlertas.forEach((k, v) {
        alertas[k.toString().toUpperCase()] = JsonParser.toInt(v);
      });
    }

    final rawMenor = json['menor_stock'];
    final List<InventarioMenorStockItem> menor = [];
    if (rawMenor is List) {
      for (final item in rawMenor) {
        if (item is Map<String, dynamic>) {
          menor.add(InventarioMenorStockItem.fromJson(item));
        } else if (item is Map) {
          menor.add(InventarioMenorStockItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return InventarioDashboardData(
      alertasPorNivel: alertas,
      menorStock: menor,
      materiasBajoMinimo: JsonParser.toInt(json['materias_bajo_minimo']),
      movimientosMes: JsonParser.toInt(json['movimientos_mes']),
    );
  }

  factory InventarioDashboardData.empty() {
    return const InventarioDashboardData(
      alertasPorNivel: {},
      menorStock: [],
      materiasBajoMinimo: 0,
      movimientosMes: 0,
    );
  }
}

class DashboardData {
  final DashboardKpis kpis;
  final List<VentasPorMesItem> ventasPorMes;
  final List<VentasPorMedioItem> ventasPorMedio;
  final List<ProduccionPorMesItem> produccionPorMes;
  final Map<String, int> ordenesPorEstado;
  final InventarioDashboardData inventario;
  final int meses;

  const DashboardData({
    required this.kpis,
    required this.ventasPorMes,
    required this.ventasPorMedio,
    required this.produccionPorMes,
    required this.ordenesPorEstado,
    required this.inventario,
    required this.meses,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json, {int meses = 6}) {
    final kpis = json['kpis'] is Map<String, dynamic>
        ? DashboardKpis.fromJson(json['kpis'] as Map<String, dynamic>)
        : (json['kpis'] is Map
            ? DashboardKpis.fromJson(Map<String, dynamic>.from(json['kpis'] as Map))
            : DashboardKpis.empty());

    final List<VentasPorMesItem> ventasMes = [];
    if (json['ventas_por_mes'] is List) {
      for (final item in json['ventas_por_mes'] as List) {
        if (item is Map<String, dynamic>) {
          ventasMes.add(VentasPorMesItem.fromJson(item));
        } else if (item is Map) {
          ventasMes.add(VentasPorMesItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final List<VentasPorMedioItem> ventasMedio = [];
    if (json['ventas_por_medio'] is List) {
      for (final item in json['ventas_por_medio'] as List) {
        if (item is Map<String, dynamic>) {
          ventasMedio.add(VentasPorMedioItem.fromJson(item));
        } else if (item is Map) {
          ventasMedio.add(VentasPorMedioItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final List<ProduccionPorMesItem> prodMes = [];
    if (json['produccion_por_mes'] is List) {
      for (final item in json['produccion_por_mes'] as List) {
        if (item is Map<String, dynamic>) {
          prodMes.add(ProduccionPorMesItem.fromJson(item));
        } else if (item is Map) {
          prodMes.add(ProduccionPorMesItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final Map<String, int> ordEstado = {};
    if (json['ordenes_por_estado'] is Map) {
      (json['ordenes_por_estado'] as Map).forEach((k, v) {
        ordEstado[k.toString()] = JsonParser.toInt(v);
      });
    }

    final invData = json['inventario'] is Map<String, dynamic>
        ? InventarioDashboardData.fromJson(json['inventario'] as Map<String, dynamic>)
        : (json['inventario'] is Map
            ? InventarioDashboardData.fromJson(Map<String, dynamic>.from(json['inventario'] as Map))
            : InventarioDashboardData.empty());

    return DashboardData(
      kpis: kpis,
      ventasPorMes: ventasMes,
      ventasPorMedio: ventasMedio,
      produccionPorMes: prodMes,
      ordenesPorEstado: ordEstado,
      inventario: invData,
      meses: meses,
    );
  }
}

class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  static DashboardService get instance => _instance;
  DashboardService._internal();

  Future<DashboardData> obtenerDatosDashboard({int meses = 6}) async {
    final response = await ApiClient.instance.dio.get(
      '/dashboard',
      queryParameters: {'meses': meses},
    );
    final data = ApiResponseParser.extractData(response.data);
    if (data is Map<String, dynamic>) {
      return DashboardData.fromJson(data, meses: meses);
    } else if (data is Map) {
      return DashboardData.fromJson(Map<String, dynamic>.from(data), meses: meses);
    }
    throw Exception('Formato de respuesta no válido en /dashboard');
  }
}
