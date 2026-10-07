# AgroLink (app Flutter)

App móvil del marketplace agropecuario **AgroLink** para México. Flutter + Riverpod + go_router, conectada al backend Laravel real que vive en [`agrolink-api`](https://github.com/equipotec1999-cmd/agrolink-api).

**Estado:** fases 1 a 7 cerradas. En Fase 8 (producción): preparando lanzamiento.

## Qué incluye

- **Login y registro** con Sanctum, verificación en dos pasos para administradores (TOTP, Google Authenticator / Authy, códigos de respaldo).
- **Catálogo** real (categorías, tipos de producto, atributos dinámicos) traído del backend.
- **Publicaciones**: feed, búsqueda, detalle, publicar con fotos reales y ubicación aproximada.
- **Mis publicaciones**: editar, reenviar a revisión, archivar, ver motivo de rechazo.
- **Chat y ofertas**: conversaciones por publicación, ofertas, contraofertas y operaciones.
- **Favoritos y búsquedas guardadas**.
- **Perfil**: cifras reales (ventas, compras, calificación), configuración, cambio de contraseña, cerrar sesiones, verificación de vendedor.
- **Moderación**: cola de publicaciones, reportes, verificación de vendedores (para cuentas con permiso).
- **Reglas de cumplimiento**: catálogo administrable (solo para cuentas con permiso).
- **Notificaciones push** con Firebase.
- **Diseño propio**: paleta cálida (bone/ink/lime), tipografías Cinzel y Plus Jakarta Sans, glifos de categoría con los símbolos de la marca.

## Correrla

Necesitas Flutter 3.24+ y un emulador Android o un celular físico conectado por USB.

```bash
flutter pub get

# Contra el backend desplegado:
flutter run --dart-define=API_BASE_URL=https://agrolink-api-wug5.onrender.com/api

# Contra tu backend local (emulador Android):
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api

# Contra tu backend local (celular físico en la misma WiFi):
flutter run --dart-define=API_BASE_URL=http://TU_IP_LOCAL:8000/api
```

El backend local debe arrancarse con `php artisan serve --host=0.0.0.0` para que lo vea el celular.

El Android Manifest ya incluye los permisos de ubicación, cámara e internet.

## Pruebas

```bash
flutter analyze
flutter test
```

Cubre validaciones, parsing de modelos, `ApiClient`, filtros de búsqueda y utilidades. CI corre esto mismo en cada *push*.

## Estructura

```
lib/
  core/          red (ApiClient, TokenStorage), tema, utilidades, router, push
  shared/        widgets reutilizables (botones, glifos, snack, shell)
  features/
    auth/        login, registro, perfil del usuario
    security/    2FA y seguridad
    catalog/     categorías, tipos, atributos
    listings/    feed, detalle, buscar, publicar
    my_listings/ mis publicaciones, editar, reenviar
    search/      filtros, búsquedas guardadas
    chat/        conversaciones, mensajes, ofertas
    operations/  compras y ventas
    profile/     perfil, configuración
    settings/    cuenta, estadísticas
    favorites/   favoritos
    moderation/  cola, reportes, verificación de vendedores
    admin/       reglas de cumplimiento
    saved_searches/  búsquedas guardadas
    verification/    verificación de vendedor
    notifications/   centro de notificaciones
```

Cada feature sigue `domain` → `data` (interfaz + implementación) → `application` (Riverpod) → `presentation` (pantallas). Los repositorios se inyectan desde `main.dart`, así los tests pueden sustituirlos sin tocar las pantallas.

## Contrato con el backend

- La API vive en `agrolink-api`. Las claves JSON están en inglés (`title`, `price`, `status`, `type`...).
- Los **valores de estatus llegan en español** (`publicada`, `pendiente`, `aceptada`, `rechazada`, `enviada`, `contraoferta`, `vencida`, `foto`...). La app los traduce a etiquetas con las clases `OfferStatus`, `MyListing.statusLabel`, etcétera.
- La ubicación mostrada en el feed se calcula en el dispositivo (Haversine) contra la ubicación aproximada del backend.

## Diseño

- **Paleta** cálida: `bone` (fondo), `ink` (texto), `lime` (acento), `cream` (botones secundarios), `clay` (avisos). Rojo y verde para error y éxito.
- **Tipografías**: Cinzel para titulares (`AppText.hero/h1/h2/h3/overline`); Plus Jakarta Sans para precios y lectura.
- **Glifos** PNG blancos con transparencia, teñidos en código con `BlendMode.srcIn` (`CategoryGlyph`).
- **Logo** oficial en `assets/brand/`.

## Ícono de la app

Se genera desde el logo con `flutter_launcher_icons`:

```bash
dart run flutter_launcher_icons
```

Después hay que reinstalar la app (`flutter run`), no basta hot restart.
