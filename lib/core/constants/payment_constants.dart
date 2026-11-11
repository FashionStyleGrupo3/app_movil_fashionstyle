// @source-mirror: src/services/ventaServicio.js, src/services/pagoServicio.js

const Map<String, String> mediosPagoPos = {
  'efectivo': 'Efectivo',
  'tarjeta': 'Tarjeta',
  'transferencia': 'Transferencia / Nequi / Daviplata',
  'debito': 'Débito',
  'credito': 'Crédito',
};

const String claveStorageConfig = 'fs_config_pasarela_pagos';
