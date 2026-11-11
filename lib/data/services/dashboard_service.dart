// @source-mirror: src/views/admin/VistaPanelControl.vue, src/components/admin/GraficoPanel.vue
import 'package:fashion_style_mobile/core/network/api_client.dart';
import 'package:fashion_style_mobile/core/network/api_response_parser.dart';
import 'package:fashion_style_mobile/data/models/dashboard/dashboard_models.dart';

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
    throw Exception('No fue posible interpretar los datos del panel.');
  }
}
