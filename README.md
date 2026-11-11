# Fashion Style Móvil (Android) &bull; v1.3.0

Aplicación móvil oficial para la gestión integral y comercio electrónico de la boutique **Fashion Style**, conectada al backend REST en Laravel y Wompi Bancolombia.

[![Versión](https://img.shields.io/badge/version-1.3.0%2B7-B83A24.svg)](https://github.com/FashionStyleGrupo3/app_movil_fashionstyle/releases/tag/v1.3.0)
[![Descargar APK](https://img.shields.io/badge/Descargar-fashionstyle--release.apk-115E59.svg)](https://github.com/FashionStyleGrupo3/app_movil_fashionstyle/releases/download/v1.3.0/fashionstyle-release.apk)

## 📲 Descarga Directa del Instalador

Puedes descargar e instalar el archivo APK de la versión más reciente (`v1.3.0`) directamente desde el siguiente enlace oficial:

👉 **[Descargar Fashion Style Móvil v1.3.0](https://github.com/FashionStyleGrupo3/app_movil_fashionstyle/releases/download/v1.3.0/fashionstyle-release.apk)**

Enlace alternativo directo en repositorio:
👉 [fashionstyle-release.apk (instalador local)](https://raw.githubusercontent.com/FashionStyleGrupo3/app_movil_fashionstyle/main/instalador/fashionstyle-release.apk)

---

## 📋 Requisitos e Instalación
- **Sistema Operativo:** Android 8.0 (Oreo) o superior.
- **Pasos:**
  1. Descarga el archivo `fashionstyle-release.apk` en tu dispositivo Android.
  2. Al abrirlo, si el sistema lo solicita, autoriza la opción de *«Permitir desde esta fuente»* (Instalar aplicaciones desconocidas).
  3. Presiona **Instalar** y abre la aplicación.

---

## 🚀 Funcionalidades Principales

### 🛍️ Clientes y Comercio Electrónico (Storefront & Lookbook)
- **Identidad Neo-Atelier:** Fondos minerales ultra limpios (`#F6F7F9`), acentos Terracotta Couture (`#B83A24`), detalles Jade de taller (`#115E59`) y tipografía sartorial (`Space Grotesk`, `Plus Jakarta Sans`, `JetBrains Mono`).
- **Lookbook 3:4:** Exploración de prendas en tarjetas proporción lookbook con badge de descuento en terracotta, selector circular de favoritos y botón de adición rápida.
- **Bolsa y Checkout:** Modal nativo con ajuste de cantidades, generación de cotización en PDF y botón de checkout optimizado.
- **Pasarela de Pago Wompi Bancolombia:** Integración con PSE, tarjetas débito/crédito y Nequi, con retorno automático («Volver al comercio»), Deep Links y conciliación de órdenes.
- **Mi Perfil:** Credencial ejecutiva con badge de rol, historial de compras, descarga de facturas DIAN A4 y gestión de datos.

### 💼 Ventas en Punto de Venta (POS)
- Módulo de mostrador rápido para vendedores y personal de tienda física.
- Cobro multimedio (Efectivo, Wompi, Nequi, Daviplata), cálculo automático de cambio y generación/impresión inmediata de recibo térmico de 80mm en PDF.

### ⚙️ Administración y Taller (Admin Cockpit)
- **Panel de Control & Gráficos CustomPainter:** Bento KPIs interactivos, gráfico de barras apiladas (POS vs Web), dona de distribución de medios de pago, gráfico de líneas de producción y dona de alertas de inventario.
- **Inventario y Kárdex:** Monitoreo de stock bajo, entradas y salidas por compras, ventas y devoluciones, con tarjetas minerales y exportación CSV.
- **Gestión de Prendas:** Creación, edición y activación/desactivación de prendas, tallas y promociones con modales de 28px de radio.
- **Producción:** Simulador técnico de costos textiles y gestión de órdenes de confección.
- **Facturación y Pedidos:** Gestión de despachos, generación de facturas electrónicas DIAN y descarga en PDF.
- **Seguridad y Auditoría:** Control de acceso por roles (Administrador, Empleado, Cliente) y bitácora de auditoría detallada.

---

## 🛠️ Tecnologías y Arquitectura
- **Framework:** Flutter 3.x / Dart 3.x
- **Gestión de Estado:** Flutter Riverpod
- **Navegación:** GoRouter con verificación reactiva de roles y doble shell (PublicShellLayout / AdminShellLayout)
- **Consumo API:** Dio (Cliente REST con interceptores de autenticación, reintentos y ChangeBus)
- **Backend API:** Laravel 11 / Sanctum / Reverb WebSockets
