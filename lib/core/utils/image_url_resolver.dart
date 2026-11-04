// @source-mirror: src/composables/useImagenStorage.js

class ImageUrlResolver {
  static const String defaultBaseUrl = 'https://fashionstyle.api.adsocidm.com/storage';
  static const String placeholderAsset = 'assets/images/prenda-respaldo.png';

  static String resolve(
    dynamic value, {
    String baseUrl = defaultBaseUrl,
  }) {
    String? rawPath;

    if (value is Map<String, dynamic>) {
      rawPath = (value['url'] ?? value['ruta'] ?? value['imagen'])?.toString();
    } else if (value is String) {
      rawPath = value;
    }

    if (rawPath == null || rawPath.trim().isEmpty) {
      return '';
    }

    final trimmed = rawPath.trim();

    // Data URI o Blob
    if (trimmed.startsWith('data:') || trimmed.startsWith('blob:')) {
      return trimmed;
    }

    // URL completa HTTP / HTTPS
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    // Ruta relativa normalizada
    final cleanPath = trimmed
        .replaceFirst(RegExp(r'^/?storage/'), '')
        .replaceFirst(RegExp(r'^/+'), '');

    final cleanBase = baseUrl.replaceAll(RegExp(r'/+$'), '');

    return '$cleanBase/$cleanPath';
  }
}
