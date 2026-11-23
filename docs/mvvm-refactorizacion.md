# Refactorización a MVVM — BYbooKS (Práctica 5)

> **Actualizado en la Práctica 8** para reflejar la versión final: la estructura incluye ahora `Services/` y los modelos de la API, y los *Pendientes* indican cuáles se resolvieron. Detalles técnicos en [`documentacion-tecnica.md`](documentacion-tecnica.md).

**Integrantes:** Yael Alam González Prospero · Bryan Ricardo Laurrabaquio Ramirez


## 1. Estructura final

```
Proyecto Bry y Yael/
├── Models/
│   ├── Book.swift                  (+ extensión con `subtitle` y `coverURL`)
│   ├── BookStore.swift             (fuente única de verdad: catálogo y favoritos)
│   ├── FavoriteBook.swift          (registro persistente de SwiftData)
│   ├── LoadState.swift             (idle, loading, content, empty, error)
│   └── OpenLibraryDTO.swift        (respuesta de la API → Book)
├── Services/
│   ├── BookService.swift           (OpenLibraryService, detrás de un protocolo)
│   ├── BookServiceError.swift
│   └── FavoritesService.swift      (SwiftData; versión en memoria para pruebas)
├── ViewModels/
│   ├── BookListViewModel.swift
│   ├── BookDetailViewModel.swift
│   └── FavoritesViewModel.swift
├── Views/
│   ├── ContentView.swift
│   ├── SecondView.swift
│   ├── FavoritesView.swift
│   └── Components/ (BookRow, SearchField, Theme)
└── Proyecto_Bry_y_YaelApp.swift
```

## 2. Qué lógica salió de cada vista

| Antes (en la vista) | Ahora | Dónde |
|---|---|---|
| `filteredBooks` en `ContentView` | `filteredBooks` (por título o autor, sin espacios sobrantes) | `BookListViewModel` |
| `if filteredBooks.isEmpty` en `ContentView` | `noResults` | `BookListViewModel` |
| `store.favorites.count` en `ContentView` | `favoritesCount` | `BookListViewModel` |
| `@State searchText` en `ContentView` | `searchText` | `BookListViewModel` |
| `saved` y `store.toggleFavorite` en `SecondView` | `isSaved`, `toggleSaved()` | `BookDetailViewModel` |
| `saved ? "Guardado" : "Guardar"` y la etiqueta de VoiceOver | `buttonTitle`, `buttonAccessibilityLabel` | `BookDetailViewModel` |
| `store.favorites.isEmpty` en `FavoritesView` | `favorites`, `isEmpty`, `removeFavorite(_:)` | `FavoritesViewModel` |
| `year + " - " + genre` en `BookRow` | `Book.subtitle` | `Book` (dato calculado del Model) |

**Lógica agregada después, ya dentro del ViewModel:**

| Lógica | Dónde |
|---|---|
| Descargar el catálogo y manejar sus estados (`loadIfNeeded`, `retry`, `loadBooks`) | `BookListViewModel` |
| Elegir 10 libros al azar y cambiarlos al jalar la lista (`refreshRandomBooks`) | `BookListViewModel` |
| Buscar en Open Library al dejar de escribir o al presionar *Buscar* (`searchAfterTyping`, `search`, `searchState`) e ignorar respuestas viejas | `BookListViewModel` |
| Cargar la descripción del libro y los textos de año, género y descripción (`loadDescription`, `yearText`, `genreText`, `descriptionText`) | `BookDetailViewModel` |

**Se quedó en las vistas:** layout, colores, modifiers, `NavigationStack`/`NavigationLink`/`navigationDestination` y los textos fijos de la interfaz.


## 3. Problemas encontrados y corregidos

- `BookRow` armaba el texto `año - género` dentro de la vista → movido a `Book.subtitle`.
- `ContentView` repetía el cálculo de "sin resultados" y contaba favoritos → ahora los expone el ViewModel.
- `SecondView` decidía el texto del botón y su etiqueta → ahora los expone el ViewModel.
- Los previews dependían de `.environment(BookStore())`; ahora crean el ViewModel que necesita cada vista.

## 4. Pendientes: estado actual

| Pendiente (Práctica 5) | Estado |
|---|---|
| Renombrar `ContentView` → `BookListView` y `SecondView` → `BookDetailView` | **Abierto** |
| Cambiar a `let` las propiedades de `Book` que no se editan | **Abierto** (siguen siendo `var`) |
| `id = UUID()` cambiaba en cada ejecución y con la API se perderían los favoritos | **Resuelto:** `Book.id` es la clave (`key`) de Open Library |
| Buscar también por autor y recortar espacios en blanco | **Resuelto** en `BookListViewModel.filteredBooks` |
| Que los ViewModels dependan de un protocolo y no de la clase concreta `BookStore` | **Abierto:** los servicios sí van detrás de protocolos, pero `BookStore` sigue siendo una clase concreta |
| Los ViewModels de Detalle y Favoritos se crean dentro de `navigationDestination` y `body`, por lo que se recrean al actualizarse la vista | **Abierto** (el de Inicio sí vive en un `@State`) |
| Definir una sola forma de entregar el `BookStore` (`@Environment` o `init`) | **Resuelto:** se entrega por `init` desde la `App` |
| Conectar `FavoritesViewModel.removeFavorite` a la interfaz (deslizar o botón en Favoritos) | **Abierto:** está probado, pero ninguna vista lo usa; los libros se quitan desde el detalle |
| `FavoritesView` no debería depender del `navigationDestination` de `ContentView` | **Abierto:** funciona porque se abre dentro del mismo stack, pero es frágil |
