# Fashion Style Móvil (Android) · v1.6.2

Aplicación móvil oficial para la gestión integral y comercio electrónico de la boutique **Fashion Style**, conectada al backend REST en Laravel y Wompi Bancolombia.

[![Versión](https://img.shields.io/badge/version-1.6.2%2B17-B83A24.svg)](https://github.com/FashionStyleGrupo3/app_movil_fashionstyle/releases/tag/v1.6.2)
[![Descargar APK](https://img.shields.io/badge/Descargar-fashionstyle--release.apk-115E59.svg)](https://github.com/FashionStyleGrupo3/app_movil_fashionstyle/releases/download/v1.6.2/fashionstyle-release.apk)

## 📲 Descarga Directa del Instalador

Puedes descargar e instalar el archivo APK de la versión más reciente (`v1.6.2`) directamente desde el siguiente enlace oficial:

👉 **[Descargar Fashion Style Móvil v1.6.2](https://github.com/FashionStyleGrupo3/app_movil_fashionstyle/releases/download/v1.6.2/fashionstyle-release.apk)**

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
- **Identidad Neo-Atelier:** Fondos minerales ultra limpios (`#F7F4EF`), acentos Terracotta Couture (`#B85338`), detalles Jade de taller (`#115E59`) y tipografía sartorial (`Space Grotesk`, `Plus Jakarta Sans`, `JetBrains Mono`).
- **Navegación Limpia y Dock Sartorial:** Barra superior minimalista con isotipo `FASHIONSTYLE` y barra inferior edge-to-edge de 5 pestañas (#111111) con bloque activo invertido en tono claro (#F7F4EF).
- **Perfil Compacto:** Franja de identidad sartorial (avatar cuadrado #111111 56x56 con badge de cámara terracota #B85338), barra edge-to-edge de 3 columnas (Mis datos | Mis pedidos | Favoritos) y Bento Grid 3×2 con accesos directos y subpaneles en 2 columnas (Teléfono | Ciudad).
- **Editor y Recortador 1:1:** Herramienta interactiva nativa Flutter de recorte con zoom (1.0x-4.0x), rotación a 90° y encuadre cuadrado para avatares y fotos de catálogo.
- **Lookbook 3:4:** Exploración de prendas en tarjetas proporción lookbook con badge de descuento en terracotta, selector circular de favoritos y botón de adición rápida.
- **Bolsa y Checkout:** Modal nativo con ajuste de cantidades, generación de cotización en PDF y botón de checkout optimizado.
- **Pasarela de Pago Wompi Bancolombia:** Integración con PSE, tarjetas débito/crédito y Nequi, con retorno automático («Volver al comercio»), Deep Links y conciliación de órdenes.

### 💼 Ventas en Punto de Venta (POS)
- Módulo de mostrador rápido para vendedores y personal de tienda física.
- Cobro multimedio (Efectivo, Wompi, Nequi, Daviplata), cálculo automático de cambio y generación/impresión inmediata de recibo térmico de 80mm en PDF.

### ⚙️ Administración y Taller (Admin Cockpit)
- **Panel de Control & Gráficos CustomPainter:** Bento KPIs interactivos, gráfico de barras apiladas (POS vs Web), dona de distribución de medios de pago, gráfico de líneas de producción y dona de alertas de inventario.
- **Inventario y Kárdex:** Monitoreo de stock bajo, entradas y salidas por compras, ventas y devoluciones, con tarjetas minerales y exportación CSV.
- **Gestión de Prendas:** Creación, edición y activación/desactivación de prendas, tallas y promociones con modales y recorte de fotos 1:1.
- **Producción:** Fórmulas por prenda con cálculo de desperdicio y costo estimado, gestión de órdenes con cancelación en 2 pasos y trazabilidad de materiales.
- **Facturación y Pedidos:** Gestión de despachos, generación de facturas electrónicas DIAN y descarga en PDF.
- **Seguridad y Auditoría:** Control de acceso por roles (Administrador, Empleado, Cliente) y bitácora de auditoría detallada.
- **Módulos de Ayuda y PQRS:** Centro de ayuda con 12 guías y buzón de mensajes/PQRS con respuestas por correo electrónico.

---

## 🛠️ Tecnologías y Arquitectura
- **Framework:** Flutter 3.x / Dart 3.x
- **Gestión de Estado:** Flutter Riverpod
- **Navegación:** GoRouter con verificación reactiva de roles y doble shell (PublicShellLayout / AdminShellLayout)
- **Consumo API:** Dio (Cliente REST con interceptores de autenticación, reintentos y ChangeBus)
- **Backend API:** Laravel 11 / Sanctum / Reverb WebSockets
