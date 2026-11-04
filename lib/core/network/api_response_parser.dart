// @source-mirror: src/utils/respuestaApi.js
import 'package:dio/dio.dart';

class PaginatedResponse<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;

  const PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMorePages => currentPage < lastPage;
  List<T> get lista => items;
  int get totalPaginas => lastPage;
}

class JsonParser {
  static int toInt(dynamic v, [int def = 0]) {
    if (v == null) return def;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final parsed = int.tryParse(v.trim());
      if (parsed != null) return parsed;
      final doubleParsed = double.tryParse(v.trim());
      if (doubleParsed != null) return doubleParsed.toInt();
    }
    return def;
  }

  static double toDouble(dynamic v, [double def = 0.0]) {
    if (v == null) return def;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) {
      final sanitized = v.trim().replaceAll(',', '.');
      final parsed = double.tryParse(sanitized);
      if (parsed != null) return parsed;
    }
    return def;
  }

  static bool toBool(dynamic v, [bool def = false]) {
    if (v == null) return def;
    if (v is bool) return v;
    if (v is num) return v == 1;
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'activa' || s == 'activo' || s == 'si' || s == 'yes') {
        return true;
      }
      if (s == 'false' || s == '0' || s == 'inactiva' || s == 'inactivo' || s == 'no') {
        return false;
      }
    }
    return def;
  }

  static String toStr(dynamic v, [String def = '']) {
    if (v == null) return def;
    if (v is String) return v.trim();
    return v.toString().trim();
  }
}

class ApiResponseParser {
  static dynamic extractData(dynamic responseOrData) {
    final raw = responseOrData is Response ? responseOrData.data : responseOrData;
    if (raw is Map<String, dynamic>) {
      return raw['data'] ?? raw;
    }
    return raw;
  }

  static PaginatedResponse<T> extractPaginated<T>(
    dynamic responseOrData,
    T Function(Map<String, dynamic> map) fromJson,
  ) {
    final raw = responseOrData is Response ? responseOrData.data : responseOrData;
    Map<String, dynamic> body = {};
    if (raw is Map<String, dynamic>) {
      body = raw;
    }

    final rawData = body['data'] ?? body;
    List<dynamic> rawList = [];
    Map<String, dynamic> meta = {};

    if (rawData is List) {
      rawList = rawData;
      if (body['meta'] is Map<String, dynamic>) {
        meta = body['meta'] as Map<String, dynamic>;
      } else if (body['pagination'] is Map<String, dynamic>) {
        meta = body['pagination'] as Map<String, dynamic>;
      } else {
        meta = body;
      }
    } else if (rawData is Map<String, dynamic> && rawData['data'] is List) {
      rawList = rawData['data'] as List;
      if (rawData['meta'] is Map<String, dynamic>) {
        meta = rawData['meta'] as Map<String, dynamic>;
      } else {
        meta = rawData;
      }
    }

    final items = rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => fromJson(e))
        .toList();

    final currentPage = JsonParser.toInt(meta['current_page'], 1);
    final lastPage = JsonParser.toInt(meta['last_page'], 1);
    final total = JsonParser.toInt(meta['total'], items.length);

    return PaginatedResponse<T>(
      items: items,
      currentPage: currentPage < 1 ? 1 : currentPage,
      lastPage: lastPage < 1 ? 1 : lastPage,
      total: total < 0 ? 0 : total,
    );
  }
}
