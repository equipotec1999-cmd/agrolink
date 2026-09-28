// ⚠️ MOCK — Datos de ejemplo para el prototipo. En producción el catálogo
// se administra desde el backend (seeders + panel de administración).

import '../../domain/catalog.dart';
import '../catalog_repository.dart';

class MockCatalogRepository implements CatalogRepository {
  @override
  Future<Catalog> load() async => const Catalog(categories: _categories, productTypes: _types);
}

const _categories = [
  AgroCategory(id: 'animales', name: 'Animales', emoji: 'cow', tagline: 'Ganado y especies de producción'),
  AgroCategory(id: 'apicultura', name: 'Apicultura', emoji: 'bee', tagline: 'Colmenas, reinas y miel'),
  AgroCategory(id: 'agricultura', name: 'Agricultura', emoji: 'chili', tagline: 'Cosechas, semillas y plantas'),
];

const _sexo = AttributeDef(
  key: 'sexo',
  label: 'Sexo',
  type: AttributeDataType.select,
  options: ['Macho', 'Hembra'],
  required: true,
  filterable: true,
);

const _peso = AttributeDef(
  key: 'peso',
  label: 'Peso',
  type: AttributeDataType.number,
  unit: 'kg',
  required: true,
  filterable: true,
  min: 0,
  max: 900,
);

const _edadMeses = AttributeDef(
  key: 'edad_meses',
  label: 'Edad',
  type: AttributeDataType.number,
  unit: 'meses',
  required: true,
  filterable: true,
  min: 0,
  max: 120,
);

const _condicion = AttributeDef(
  key: 'condicion_corporal',
  label: 'Condición corporal',
  type: AttributeDataType.select,
  options: ['1', '2', '3', '4', '5'],
  hint: 'Escala 1 (flaco) a 5 (obeso)',
);

const _estadoReproductivo = AttributeDef(
  key: 'estado_reproductivo',
  label: 'Estado reproductivo',
  type: AttributeDataType.select,
  options: ['No aplica', 'Vacía', 'Gestante', 'Lactando', 'Semental activo'],
  group: AttributeGroup.reproduccion,
);

const _partos = AttributeDef(
  key: 'partos',
  label: 'Número de partos',
  type: AttributeDataType.number,
  group: AttributeGroup.reproduccion,
);

// Atributos sanitarios reutilizables (una sola definición, muchos tipos).
const _salud = [
  AttributeDef(
    key: 'vacunacion',
    label: 'Vacunación',
    type: AttributeDataType.select,
    options: ['Al corriente', 'Parcial', 'Sin registro'],
    required: true,
    group: AttributeGroup.salud,
  ),
  AttributeDef(
    key: 'desparasitacion',
    label: 'Última desparasitación',
    type: AttributeDataType.date,
    group: AttributeGroup.salud,
  ),
  AttributeDef(
    key: 'estado_sanitario',
    label: 'Estado sanitario',
    type: AttributeDataType.select,
    options: ['Sano', 'En tratamiento', 'En observación'],
    required: true,
    group: AttributeGroup.salud,
  ),
  AttributeDef(
    key: 'enfermedades',
    label: 'Enfermedades conocidas',
    type: AttributeDataType.text,
    group: AttributeGroup.salud,
  ),
  AttributeDef(
    key: 'tratamientos',
    label: 'Tratamientos',
    type: AttributeDataType.text,
    group: AttributeGroup.salud,
  ),
];

const _animalPrices = [PriceType.perAnimal, PriceType.perKg, PriceType.perLot, PriceType.quote];
const _producePrices = [PriceType.perKg, PriceType.perUnit, PriceType.perLot, PriceType.quote];

const _cosecha = [
  AttributeDef(key: 'variedad', label: 'Variedad', type: AttributeDataType.text, required: true, filterable: true),
  AttributeDef(
    key: 'metodo_cultivo',
    label: 'Método de cultivo',
    type: AttributeDataType.select,
    options: ['Convencional', 'Orgánico (sin certificar)', 'Orgánico certificado'],
    required: true,
    filterable: true,
  ),
  AttributeDef(
    key: 'sistema',
    label: 'Sistema',
    type: AttributeDataType.select,
    options: ['Campo abierto', 'Invernadero', 'Malla sombra'],
  ),
  AttributeDef(key: 'fecha_cosecha', label: 'Fecha de cosecha', type: AttributeDataType.date, required: true),
  AttributeDef(
    key: 'calidad',
    label: 'Calidad',
    type: AttributeDataType.select,
    options: ['Primera', 'Segunda', 'Tercera'],
    required: true,
    filterable: true,
  ),
  AttributeDef(
    key: 'madurez',
    label: 'Madurez',
    type: AttributeDataType.select,
    options: ['Verde', 'Pintón', 'Maduro'],
  ),
  AttributeDef(
    key: 'presentacion',
    label: 'Presentación',
    type: AttributeDataType.select,
    options: ['Granel', 'Caja', 'Arpilla', 'Tonelada'],
    group: AttributeGroup.comercial,
  ),
  AttributeDef(
    key: 'disponible_kg',
    label: 'Disponibilidad',
    type: AttributeDataType.number,
    unit: 'kg',
    required: true,
    filterable: true,
    min: 0,
    max: 20000,
    group: AttributeGroup.comercial,
  ),
  AttributeDef(
    key: 'pedido_minimo',
    label: 'Pedido mínimo',
    type: AttributeDataType.number,
    unit: 'kg',
    group: AttributeGroup.comercial,
  ),
];

const _types = [
  // ───────────── ANIMALES ─────────────
  ProductType(
    id: 'equinos',
    categoryId: 'animales',
    name: 'Caballos',
    emoji: 'horse',
    priceTypes: _animalPrices,
    attributes: [
      AttributeDef(
        key: 'raza',
        label: 'Raza',
        type: AttributeDataType.select,
        options: ['Cuarto de Milla', 'Azteca', 'Pura Sangre', 'Criollo', 'Appaloosa', 'Otra'],
        required: true,
        filterable: true,
      ),
      AttributeDef(
        key: 'sexo',
        label: 'Sexo',
        type: AttributeDataType.select,
        options: ['Macho', 'Hembra', 'Macho castrado'],
        required: true,
        filterable: true,
      ),
      AttributeDef(
        key: 'edad_anios',
        label: 'Edad',
        type: AttributeDataType.number,
        unit: 'años',
        required: true,
        filterable: true,
        min: 0,
        max: 30,
      ),
      AttributeDef(key: 'peso', label: 'Peso', type: AttributeDataType.number, unit: 'kg'),
      AttributeDef(key: 'altura', label: 'Altura a la cruz', type: AttributeDataType.number, unit: 'm'),
      AttributeDef(key: 'color', label: 'Color / capa', type: AttributeDataType.text),
      AttributeDef(
        key: 'disciplina',
        label: 'Disciplina',
        type: AttributeDataType.select,
        options: ['Rienda', 'Charrería', 'Trabajo de campo', 'Paseo', 'Carreras', 'Salto'],
        filterable: true,
      ),
      AttributeDef(
        key: 'entrenamiento',
        label: 'Nivel de entrenamiento',
        type: AttributeDataType.select,
        options: ['Sin domar', 'Básico', 'Intermedio', 'Avanzado'],
      ),
      AttributeDef(
        key: 'temperamento',
        label: 'Temperamento',
        type: AttributeDataType.select,
        options: ['Dócil', 'Moderado', 'Enérgico'],
      ),
      AttributeDef(key: 'genealogia', label: 'Genealogía', type: AttributeDataType.text, group: AttributeGroup.reproduccion),
      _estadoReproductivo,
      ..._salud,
    ],
  ),
  ProductType(
    id: 'bovinos',
    categoryId: 'animales',
    name: 'Bovinos',
    emoji: 'cow',
    priceTypes: _animalPrices,
    attributes: [
      AttributeDef(
        key: 'raza',
        label: 'Raza',
        type: AttributeDataType.select,
        options: ['Brahman', 'Suizo', 'Brahman x Suizo', 'Nelore', 'Gyr', 'Holstein', 'Charolais', 'Angus', 'Otra'],
        required: true,
        filterable: true,
      ),
      _sexo,
      _edadMeses,
      _peso,
      AttributeDef(
        key: 'proposito',
        label: 'Propósito',
        type: AttributeDataType.select,
        options: ['Engorda', 'Cría', 'Leche', 'Doble propósito', 'Pie de cría'],
        required: true,
        filterable: true,
      ),
      AttributeDef(key: 'arete', label: 'Identificación / arete', type: AttributeDataType.text),
      _condicion,
      _estadoReproductivo,
      _partos,
      AttributeDef(
        key: 'leche_litros',
        label: 'Producción de leche',
        type: AttributeDataType.number,
        unit: 'L/día',
        group: AttributeGroup.produccion,
      ),
      ..._salud,
    ],
  ),
  ProductType(
    id: 'ovinos',
    categoryId: 'animales',
    name: 'Ovinos',
    emoji: 'sheep',
    priceTypes: _animalPrices,
    attributes: [
      AttributeDef(
        key: 'raza',
        label: 'Raza',
        type: AttributeDataType.select,
        options: ['Pelibuey', 'Katahdin', 'Dorper', 'Blackbelly', 'Cruza'],
        required: true,
        filterable: true,
      ),
      _sexo,
      _edadMeses,
      _peso,
      AttributeDef(
        key: 'proposito',
        label: 'Propósito',
        type: AttributeDataType.select,
        options: ['Engorda', 'Pie de cría', 'Reproductor'],
        required: true,
        filterable: true,
      ),
      _condicion,
      _estadoReproductivo,
      _partos,
      ..._salud,
    ],
  ),
  ProductType(
    id: 'caprinos',
    categoryId: 'animales',
    name: 'Caprinos',
    emoji: 'goat',
    priceTypes: _animalPrices,
    attributes: [
      AttributeDef(
        key: 'raza',
        label: 'Raza',
        type: AttributeDataType.select,
        options: ['Saanen', 'Alpina', 'Nubia', 'Boer', 'Criolla'],
        required: true,
        filterable: true,
      ),
      _sexo,
      _edadMeses,
      _peso,
      AttributeDef(
        key: 'proposito',
        label: 'Propósito',
        type: AttributeDataType.select,
        options: ['Leche', 'Carne', 'Pie de cría'],
        required: true,
        filterable: true,
      ),
      AttributeDef(
        key: 'leche_litros',
        label: 'Producción de leche',
        type: AttributeDataType.number,
        unit: 'L/día',
        group: AttributeGroup.produccion,
      ),
      _estadoReproductivo,
      _partos,
      ..._salud,
    ],
  ),
  ProductType(
    id: 'porcinos',
    categoryId: 'animales',
    name: 'Porcinos',
    emoji: 'pig',
    priceTypes: _animalPrices,
    attributes: [
      AttributeDef(key: 'genetica', label: 'Raza / genética', type: AttributeDataType.text, required: true),
      _sexo,
      _edadMeses,
      _peso,
      AttributeDef(
        key: 'proposito',
        label: 'Propósito',
        type: AttributeDataType.select,
        options: ['Engorda', 'Pie de cría', 'Semental'],
        required: true,
        filterable: true,
      ),
      AttributeDef(
        key: 'alimentacion',
        label: 'Alimentación',
        type: AttributeDataType.select,
        options: ['Alimento balanceado', 'Mixta', 'Traspatio'],
      ),
      ..._salud,
    ],
  ),
  // ───────────── APICULTURA ─────────────
  ProductType(
    id: 'colmenas',
    categoryId: 'apicultura',
    name: 'Colmenas',
    emoji: 'hive',
    priceTypes: [PriceType.perUnit, PriceType.perLot, PriceType.quote],
    attributes: [
      AttributeDef(
        key: 'tipo_colmena',
        label: 'Tipo de colmena',
        type: AttributeDataType.select,
        options: ['Langstroth', 'Jumbo', 'Dadant'],
        required: true,
        filterable: true,
      ),
      AttributeDef(key: 'alzas', label: 'Número de alzas', type: AttributeDataType.number, required: true),
      AttributeDef(key: 'bastidores', label: 'Bastidores ocupados', type: AttributeDataType.number, required: true),
      AttributeDef(key: 'bastidores_cria', label: 'Bastidores con cría', type: AttributeDataType.number),
      AttributeDef(
        key: 'genetica',
        label: 'Genética / línea',
        type: AttributeDataType.select,
        options: ['Italiana', 'Carniola', 'Africanizada', 'Local'],
        filterable: true,
      ),
      AttributeDef(
        key: 'fuerza',
        label: 'Fuerza de colonia',
        type: AttributeDataType.select,
        options: ['Débil', 'Media', 'Fuerte'],
        required: true,
      ),
      AttributeDef(key: 'edad_reina', label: 'Edad de la reina', type: AttributeDataType.number, unit: 'meses'),
      AttributeDef(key: 'ultima_inspeccion', label: 'Última inspección', type: AttributeDataType.date, group: AttributeGroup.salud),
      AttributeDef(
        key: 'estado_sanitario',
        label: 'Estado sanitario',
        type: AttributeDataType.select,
        options: ['Sana', 'En tratamiento', 'En observación'],
        required: true,
        group: AttributeGroup.salud,
      ),
    ],
  ),
  ProductType(
    id: 'nucleos',
    categoryId: 'apicultura',
    name: 'Núcleos',
    emoji: 'bee',
    priceTypes: [PriceType.perUnit, PriceType.perLot],
    attributes: [
      AttributeDef(key: 'bastidores', label: 'Bastidores', type: AttributeDataType.number, required: true),
      AttributeDef(key: 'bastidores_cria', label: 'Bastidores con cría', type: AttributeDataType.number, required: true),
      AttributeDef(key: 'reina_fecundada', label: 'Reina fecundada', type: AttributeDataType.boolean, required: true),
      AttributeDef(
        key: 'genetica',
        label: 'Genética / línea',
        type: AttributeDataType.select,
        options: ['Italiana', 'Carniola', 'Africanizada', 'Local'],
        filterable: true,
      ),
    ],
  ),
  ProductType(
    id: 'reinas',
    categoryId: 'apicultura',
    name: 'Abejas reina',
    emoji: 'crown',
    priceTypes: [PriceType.perUnit],
    attributes: [
      AttributeDef(
        key: 'genetica',
        label: 'Genética / línea',
        type: AttributeDataType.select,
        options: ['Italiana', 'Carniola', 'Africanizada', 'Local'],
        required: true,
        filterable: true,
      ),
      AttributeDef(key: 'fecundada', label: 'Fecundada', type: AttributeDataType.boolean, required: true),
      AttributeDef(key: 'marcada', label: 'Marcada', type: AttributeDataType.boolean),
    ],
  ),
  ProductType(
    id: 'miel',
    categoryId: 'apicultura',
    name: 'Miel',
    emoji: 'honey',
    priceTypes: [PriceType.perKg, PriceType.perUnit, PriceType.quote],
    attributes: [
      AttributeDef(
        key: 'tipo_miel',
        label: 'Tipo de miel',
        type: AttributeDataType.select,
        options: ['Multifloral', 'Monofloral', 'Cremosa'],
        required: true,
        filterable: true,
      ),
      AttributeDef(key: 'origen_floral', label: 'Origen floral', type: AttributeDataType.text, required: true),
      AttributeDef(key: 'fecha_cosecha', label: 'Fecha de cosecha', type: AttributeDataType.date, required: true),
      AttributeDef(key: 'lote', label: 'Lote', type: AttributeDataType.text),
      AttributeDef(
        key: 'extraccion',
        label: 'Método de extracción',
        type: AttributeDataType.select,
        options: ['Centrífuga', 'Prensado'],
      ),
      AttributeDef(
        key: 'presentacion',
        label: 'Presentación',
        type: AttributeDataType.select,
        options: ['Granel (tambo)', 'Cubeta', 'Frasco 1 kg', 'Frasco 500 g'],
        required: true,
        group: AttributeGroup.comercial,
      ),
      AttributeDef(
        key: 'disponible_kg',
        label: 'Disponibilidad',
        type: AttributeDataType.number,
        unit: 'kg',
        required: true,
        filterable: true,
        min: 0,
        max: 20000,
        group: AttributeGroup.comercial,
      ),
      AttributeDef(
        key: 'pedido_minimo',
        label: 'Pedido mínimo',
        type: AttributeDataType.number,
        unit: 'kg',
        group: AttributeGroup.comercial,
      ),
    ],
  ),
  // ───────────── AGRICULTURA ─────────────
  ProductType(
    id: 'chiles',
    categoryId: 'agricultura',
    name: 'Chiles',
    emoji: 'chili',
    priceTypes: _producePrices,
    attributes: _cosecha,
  ),
  ProductType(
    id: 'frutas',
    categoryId: 'agricultura',
    name: 'Frutas',
    emoji: 'fruit',
    priceTypes: _producePrices,
    attributes: _cosecha,
  ),
  ProductType(
    id: 'hortalizas',
    categoryId: 'agricultura',
    name: 'Hortalizas',
    emoji: 'leaf',
    priceTypes: _producePrices,
    attributes: _cosecha,
  ),
  ProductType(
    id: 'plantas',
    categoryId: 'agricultura',
    name: 'Plantas',
    emoji: 'sprout',
    priceTypes: [PriceType.perUnit, PriceType.perLot, PriceType.quote],
    attributes: [
      AttributeDef(key: 'especie', label: 'Especie', type: AttributeDataType.text, required: true, filterable: true),
      AttributeDef(key: 'variedad', label: 'Variedad', type: AttributeDataType.text, required: true),
      AttributeDef(key: 'edad_meses', label: 'Edad', type: AttributeDataType.number, unit: 'meses'),
      AttributeDef(key: 'altura_cm', label: 'Altura', type: AttributeDataType.number, unit: 'cm', required: true),
      AttributeDef(
        key: 'contenedor',
        label: 'Contenedor',
        type: AttributeDataType.select,
        options: ['Bolsa', 'Maceta', 'Charola', 'Raíz desnuda'],
        required: true,
      ),
      AttributeDef(key: 'injertada', label: 'Injertada', type: AttributeDataType.boolean, filterable: true),
      AttributeDef(key: 'patron', label: 'Patrón', type: AttributeDataType.text),
    ],
  ),
];
