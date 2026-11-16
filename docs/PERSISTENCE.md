# Persistencia local: favoritos con SwiftData

BYbooKS guarda en el dispositivo los libros que el usuario marca como favoritos. No requiere cuenta ni conexión
para consultarlos.

## 1. Qué se guarda

| Se guarda | No se guarda |
|---|---|
| Favoritos (`FavoriteBook`) | El catálogo descargado (se vuelve a pedir al abrir la app) |
| | Las descripciones (se vuelven a consultar al abrir el detalle) |
| | Las portadas (solo quedan en la caché HTTP del sistema, que iOS puede vaciar) |

## 2. Modelo persistente

`Models/FavoriteBook.swift`:

| Atributo | Tipo | Notas |
|---|---|---|
| `bookID` | `String` | `key` de la obra en Open Library (`/works/OL…W`). Identifica el favorito. |
| `title` | `String` | Título mostrado (edición en español si existe). |
| `author` | `String` | Autor o autores. |
| `year` | `String` | Texto vacío si no hay año (esquema original sin cambios). |
| `genre` | `String` | Texto vacío si no hay género. |
| `coverID` | `Int?` | **Nuevo en BYbooKS.** Portada para mostrarla en Favoritos. |
| `editionKey` | `String?` | **Nuevo en BYbooKS.** Edición, para pedir su descripción en español. |

`FavoriteBook(book:)` convierte un `Book` en registro y `toBook()` hace lo contrario.

### Migración del esquema

Los atributos `coverID` y `editionKey` son **opcionales**. SwiftData aplica entonces una migración ligera
automática: los favoritos guardados con versiones anteriores siguen cargando y solo quedan sin portada
(`nil`) hasta que el usuario los vuelve a guardar. No se eliminó ni se renombró ningún atributo.

## 3. Configuración

En `Proyecto_Bry_y_YaelApp.init()`:

```swift
let schema = Schema([FavoriteBook.self])
let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
let container = try ModelContainer(for: schema, configurations: [configuration])
let service = FavoritesService(context: ModelContext(container))
let store = BookStore(favoritesService: service, descriptionService: OpenLibraryService())
```

El contenedor se conserva como propiedad de la App para que viva mientras la app está abierta.

## 4. Servicio de favoritos

`Services/FavoritesService.swift` implementa `FavoritesServiceProtocol`:

| Método | Qué hace |
|---|---|
| `fetchFavorites()` | `FetchDescriptor<FavoriteBook>()`; devuelve `nil` si la lectura falla. |
| `saveFavorite(book:)` | Busca por `bookID` con `#Predicate`; si no existe, inserta y guarda (sin duplicados). |
| `removeFavorite(book:)` | Elimina los registros con ese `bookID` y guarda. |

`InMemoryFavoritesService` cumple el mismo protocolo sin disco; se usa en vistas previas y pruebas.

## 5. Gestión desde la interfaz

`BookStore` mantiene `favoriteRecords` y expone `isFavorite(_:)`, `toggleFavorite(_:)` y `favorites`.
Después de cada cambio vuelve a leer desde el servicio, así lo que se ve coincide con lo guardado.

Se puede guardar o quitar un favorito desde:

- el corazón de cada tarjeta en Inicio;
- el botón *Guardar / Guardado* del detalle;
- el corazón de cada tarjeta en Favoritos (quita el libro de la lista).

El contador del encabezado de Inicio se calcula a partir de los favoritos guardados.

## 6. Recuperación

Al iniciar, `BookStore.init` llama a `loadFavorites()`. Los favoritos están disponibles aunque falle la
consulta del catálogo (prueba `testFavoritosDisponiblesSinConexion`).

## 7. Limitaciones

- Los favoritos solo existen en el dispositivo: no hay sincronización con iCloud ni copia en la nube.
- Desinstalar la app borra los favoritos.
- Sin conexión, Favoritos muestra título, autor, año y género, pero la portada solo aparece si está en la caché
  y la descripción no se puede consultar.
- Los favoritos guardados antes de BYbooKS no tienen portada hasta que se quitan y se vuelven a guardar.
- El orden de la lista es el que devuelve SwiftData (no se ordena por fecha ni por título).
