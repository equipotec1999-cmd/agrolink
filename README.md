# AgroLink 🌱 — Fase 4 (en progreso): conectado a la API real

Marketplace agropecuario para México. **Login/registro, catálogo y publicaciones (feed,
detalle, publicar con fotos y ubicación reales) ya hablan con tu backend Laravel real.**
Chat/ofertas quedan para Fase 5. Favoritos sigue siendo solo local (ni siquiera se guarda
al cerrar la app) porque el backend aún no tiene endpoint de favoritos.

## Qué cambió en esta entrega (parte 2: Listings)

- Nuevas dependencias: `image_picker` (elegir fotos reales de la galería) y `geolocator`
  (ubicación real del dispositivo). Corre `flutter pub get`.
- **Importante**: son plugins nativos nuevos — hace falta **recompilar la app** (no basta
  hot reload/hot restart) y **agregar permisos a mano** en
  `android/app/src/main/AndroidManifest.xml` (dentro de `<manifest>`, antes de
  `<application>`):
  ```xml
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
  ```
- `lib/features/listings/data/api_listing_repository.dart`: feed, detalle y búsqueda reales
  (`GET /api/listings`); el buscador combina el filtro de texto/tipo del servidor con los
  filtros que el backend todavía no soporta (atributos, rango, distancia, negociable/lote),
  igual que hacía el mock.
- Publicar (asistente de 6 pasos) ahora sí llama al backend: crea el listing, sube cada
  foto elegida (`POST /listings/{id}/media`) y lo publica
  (`POST /listings/{id}/publish`). Se agregó un campo que faltaba en el asistente:
  **Unidad** (cabeza, kg, lote...), que el backend exige y antes nadie pedía porque el
  botón de publicar no hacía nada real.
- Paso de ubicación: botón "Usar mi ubicación actual" (antes solo texto libre de
  estado/municipio, que no alcanza para publicar contra el backend real).
- Fotos: ahora son fotos de verdad (`ProductArt` muestra la imagen real y usa el arte
  generado como respaldo mientras carga o si no hay foto).
- La distancia mostrada en el feed se calcula en el dispositivo (Haversine) contra la
  posición aproximada del listing; si no hay permiso de ubicación concedido, se oculta el
  "· X km" en vez de inventar un número.

## Qué cambió en la entrega anterior (parte 1: Auth + Catálogo)

- Nuevas dependencias: `http` (llamadas a la API) y `flutter_secure_storage` (guarda el
  token de sesión cifrado, nunca en texto plano). Corre `flutter pub get` después de
  descomprimir.
- `lib/core/network/`: `ApiClient` (agrega el token Bearer, decodifica errores de Laravel
  en un mensaje legible), `TokenStorage`, `ApiException`.
- `lib/core/config/env.dart`: URL de la API. Por default apunta a
  `http://10.0.2.2:8000/api` (así ve un **emulador de Android** tu propia máquina). Si
  pruebas en un **celular físico**, corre así en vez de `flutter run` a secas:
  ```
  flutter run --dart-define=API_BASE_URL=http://TU_IP_LOCAL:8000/api
  ```
  (obtén tu IP local con `ip a` o `hostname -I`; el celular debe estar en la misma red WiFi
  que tu máquina, y `php artisan serve` debe estar corriendo con `--host=0.0.0.0` para
  aceptar conexiones de fuera de tu propia máquina: `php artisan serve --host=0.0.0.0`).
- Login/registro reales contra Sanctum; la sesión se restaura sola si abres la app de
  nuevo con un token todavía válido (si no, te manda a login).
- El catálogo (categorías, tipos, atributos dinámicos) ahora viene de
  `GET /api/categories` de tu backend, no del archivo mock.
- **Nota técnica**: algunos atributos (`raza`, `proposito`, `presentacion`...) tienen
  clave distinta por tipo de producto en el backend real (ver la nota de desviación en
  `CatalogSeeder.php` del lado de Laravel) — ya actualicé los datos de ejemplo de
  publicaciones (`mock_listing_repository.dart`) para que usen las mismas claves.

## Qué SIGUE simulado (próximo paso)

- **Favoritos**: solo vive en memoria (`FavoritesController`), no hay tabla ni endpoint de
  favoritos en el backend todavía. Falta: migración + Controller en Laravel, y que Flutter
  llame a POST/DELETE en vez de guardar el Set localmente.
- **Chat y ofertas** (Fase 5): sus tablas y Models ya existen en el backend, sin
  Controllers ni pantallas reales todavía.
- `MockListingRepository` se queda solo como respaldo para tests (`test/search_test.dart`),
  ya no es lo que usa la app corriendo.

## Cómo correrlo (Debian 13 + VS Code)

```bash
cd agrolink
# 1) Genera las carpetas de plataforma (no toca lib/ ni pubspec.yaml)
flutter create . --project-name agrolink --org mx.agrolink --platforms=android,ios,web,linux
# 2) Dependencias
flutter pub get
# 3) Ejecutar (Chrome es lo más rápido para ver el diseño)
flutter run -d chrome
#    o en escritorio Linux:  flutter run -d linux
#    o en emulador Android:  flutter run
# 4) Pruebas
flutter test
```

> En Linux escritorio los emojis necesitan la fuente: `sudo apt install fonts-noto-color-emoji`

## Qué puedes probar

| Pantalla | Qué hace |
|---|---|
| Splash → Login / Registro | Animaciones, validación de formularios, recuperar contraseña |
| Inicio | Categorías, carrusel de destacados con parallax, filtro por radio (25/50/100/250 km) |
| Buscar | Búsqueda en lenguaje natural: *"borregos de engorda de 35 a 50 kg"*, *"caballos cuarto de milla menores de 8 años"* |
| Filtros | Se generan desde el catálogo (raza, propósito, calidad…) según el tipo elegido |
| Detalle | Ficha técnica con 3 niveles de confianza (declarado / documento / profesional), documentos con estado, reputación del vendedor sin depender solo de estrellas |
| Hacer oferta / Chat | Oferta → el vendedor simulado contraoferta → aceptar crea una operación |
| Publicar (+) | Asistente de 6 pasos con **atributos dinámicos** por tipo y % de completitud; no deja enviar fichas incompletas |
| Perfil, Favoritos, Notificaciones | Estados de publicación, reputación, menú |

## Estructura

```
lib/
  core/        theme, router, utils (validación, formatos)
  shared/      widgets reutilizables (botones, arte, animaciones, shell)
  features/
    auth/          application (controller) · presentation
    catalog/       domain (categorías, tipos, atributos) · data (repo + mock)
    listings/      domain · data · application · presentation
    search/        domain (filtros, intérprete de consultas) · application · presentation
    favorites/  chat/  profile/  notifications/  home/
```

Cada feature: `domain` (modelos puros) → `data` (repositorio: interfaz + implementación) →
`application` (estado con Riverpod) → `presentation` (pantallas).

## Mock vs real

Todo lo simulado está marcado con `⚠️ MOCK`. Para pasar a la API real se cambia
**solo** el provider del repositorio (p. ej. `listingRepositoryProvider`), sin tocar pantallas.

## Dependencias

- `flutter_riverpod` — estado + inyección de dependencias.
- `go_router` — rutas con URL (necesario para Flutter Web y deep links).
- Fuentes Cinzel (titulares) y Plus Jakarta Sans (lectura) incluidas (licencia OFL) — sin descargas en tiempo de ejecución.


## Rediseño rústico + logo oficial

- **Logo oficial** y **emblemas de categoría** en `assets/brand/` (PNG blancos con
  transparencia; se tiñen en código con `BlendMode.srcIn`). Widgets:
  `AgroLinkMark` / `AgroLinkWordmark` (`lib/shared/widgets/agrolink_logo.dart`) y
  `CategoryEmblem` (`lib/shared/widgets/category_glyphs.dart`, solo para las 3
  categorías raíz; los tipos de producto siguen con glifos de línea).
- **Paleta** gris cálido + verde monte (`app_colors.dart`), con un acento cálido tenue
  por categoría. Rojo/verde de error/éxito se conservan.
- **Tipografía**: Cinzel para titulares (`AppText.hero/h1/h2/h3/overline`); precios y
  texto de lectura en Plus Jakarta Sans.
- Componentes planos (sin sombras, esquinas moderadas) y divisor ornamental
  `RusticDivider` ("— ◇ —").

### Ícono de la app en el celular

Se genera desde el emblema con `flutter_launcher_icons` (config en `pubspec.yaml`):

```bash
flutter pub get
dart run flutter_launcher_icons
```

Esto reescribe los íconos dentro de `android/app/src/main/res/` (e `ios/` si existe).
Después hay que reinstalar la app (`flutter run`), no basta hot restart.
