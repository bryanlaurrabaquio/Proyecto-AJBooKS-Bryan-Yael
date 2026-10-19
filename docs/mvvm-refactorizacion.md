# Refactorización a MVVM — AJBooks (Práctica 5)

**Integrantes:** Yael Alam González Prospero · Bryan Ricardo Laurrabaquio Ramirez


## 1. Estructura final

```
Proyecto Bry y Yael/
├── Models/
│   ├── Book.swift                  (+ extensión con `subtitle`)
│   └── BookStore.swift             (sin cambios: fuente única de verdad)
├── ViewModels/
│   ├── BookListViewModel.swift     (nuevo)
│   ├── BookDetailViewModel.swift   (nuevo)
│   └── FavoritesViewModel.swift    (nuevo)
├── Views/
│   ├── ContentView.swift
│   ├── SecondView.swift
│   ├── FavoritesView.swift
│   └── Components/ (BookRow, SearchField)
└── Proyecto_Bry_y_YaelApp.swift
```

## 2. Qué lógica salió de cada vista

| Antes (en la vista) | Ahora | Dónde |
|---|---|---|
| `filteredBooks` en `ContentView` | `filteredBooks` | `BookListViewModel` |
| `if filteredBooks.isEmpty` en `ContentView` | `noResults` | `BookListViewModel` |
| `store.favorites.count` en `ContentView` | `favoritesCount` | `BookListViewModel` |
| `@State searchText` en `ContentView` | `searchText` | `BookListViewModel` |
| `saved` y `store.toggleFavorite` en `SecondView` | `isSaved`, `toggleSaved()` | `BookDetailViewModel` |
| `saved ? "Guardado" : "Guardar"` y la etiqueta de VoiceOver | `buttonTitle`, `buttonAccessibilityLabel` | `BookDetailViewModel` |
| `store.favorites.isEmpty` en `FavoritesView` | `favorites`, `isEmpty`, `removeFavorite(_:)` | `FavoritesViewModel` |
| `year + " - " + genre` en `BookRow` | `Book.subtitle` | `Book` (dato calculado del Model) |

**Se quedó en las vistas:** layout, colores, modifiers, `NavigationStack`/`NavigationLink`/`navigationDestination` y los textos fijos de la interfaz.


## 4. Problemas encontrados y corregidos

- `BookRow` armaba el texto `año - género` dentro de la vista → movido a `Book.subtitle`.
- `ContentView` repetía el cálculo de "sin resultados" y contaba favoritos → ahora los expone el ViewModel.
- `SecondView` decidía el texto del botón y su etiqueta → ahora los expone el ViewModel.
- Los previews dependían de `.environment(BookStore())`; ahora crean el ViewModel que necesita cada vista.

## 5. Pendientes

- Renombrar `ContentView` → `BookListView` y `SecondView` → `BookDetailView`.
- Cambiar a `let` las propiedades de `Book` que no se editan.
- Por ahora se usa `id = UUID()` cambia cada vez que se crea el libro, y con la API se perderían los favoritos. Usar el `key` de Open Library.
- Buscar también por autor y recortar espacios en blanco.
- Que los ViewModels dependan de un protocolo y no de la clase concreta `BookStore`.
- Los ViewModels se crean dentro de `body` y de `navigationDestination`, por lo que se recrean en cada actualización. Decidir dónde viven.
- Definir una sola forma de entregar el `BookStore` (`@Environment` o `init`). El plan decía `@Environment`, pero el código usa `init`.
- Conectar `FavoritesViewModel.removeFavorite` a la interfaz (swipe o botón en Favoritos). Está probado pero ninguna vista lo usa.
- Revisar que `FavoritesView` no dependa del `navigationDestination` de `ContentView` (funciona hoy, pero es frágil).

