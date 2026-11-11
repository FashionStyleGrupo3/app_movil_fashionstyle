// @source-mirror: src/services/pedidoServicio.js, src/services/facturaServicio.js

const Map<String, String> estadosPedido = {
  'Pendiente_Pago': 'Pendiente de pago',
  'Pagado': 'Pagado',
  'En_Preparacion': 'En preparación',
  'Enviado': 'Enviado',
  'Entregado': 'Entregado',
  'Cancelado': 'Cancelado',
  'Revision_Pago': 'Pago en revisión',
  'Expirado': 'Expirado',
  'Rechazado': 'Pago rechazado',
};

const List<String> estadosSinFlujo = [
  'Cancelado',
  'Expirado',
  'Rechazado',
  'Revision_Pago',
];

const List<String> estadosConGuia = [
  'Enviado',
  'Entregado',
];

const List<String> transportadorasSugeridas = [
  'Servientrega',
  'Coordinadora',
  'Interrapidísimo',
  'Envía',
  'TCC',
  'Deprisa',
  '4-72',
];

const Map<String, String> estadosAlternos = {
  'pendiente': 'Pendiente_Pago',
  'pagado': 'Pagado',
  'preparacion': 'En_Preparacion',
  'en_preparacion': 'En_Preparacion',
  'enviado': 'Enviado',
  'entregado': 'Entregado',
  'cancelado': 'Cancelado',
  'revision_pago': 'Revision_Pago',
  'expirado': 'Expirado',
  'rechazado': 'Rechazado',
};

String normalizarEstadoPedido(dynamic valor) {
  if (valor == null) return 'Pendiente_Pago';
  final str = valor.toString().toLowerCase();
  return estadosAlternos[str] ?? valor.toString();
}
