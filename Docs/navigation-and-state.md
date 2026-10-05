***Navegación y organización del estado: AJBooks***

***Proyecto:***
- AJBooks
***Integrantes:***
- Yael Alam González Prospero
- Bryan Ricardo Laurrabaquio Ramirez

Este documento analiza las pantallas del MVP, la información que usa cada una y dónde debería vivir cada dato, antes de implementarlo.

------------------------------------------------------------------------------------------------------------------------------------------------

### 0. Resumen del MVP ###

AJBooks es una app para descubrir libros en tendencia, buscarlos por título y ver su detalle. El usuario puede guardar los libros que le interesan.

Flujo principal: abrir la app → ver la lista de libros → buscar (opcional) → entrar al detalle → guardar como favorito → consultar favoritos.

Estado actual del código:

| Archivo | Contenido |

| `ContentView.swift` | Modelo `Book`, arreglo `books` y pantalla de lista con búsqueda |
| `SecondView.swift` | Pantalla de detalle con botón Guardar |
| `Proyecto_Bry_y_YaelApp.swift` | Punto de entrada de la app |

------------------------------------------------------------------------------------------------------------------------------------------------

### 1. Mapa de navegación ###

Pantallas del MVP:

| # | Pantalla | Archivo | Estado |

| 1 | Inicio: lista de libros con búsqueda | `ContentView.swift` | Existe |
| 2 | Detalle del libro | `SecondView.swift` | Existe |
| 3 | Favoritos | `FavoritesView.swift` | Propuesta |

Se propone la pantalla de Favoritos porque hoy el botón "Guardar" no tiene donde dejar los libros que se marquen como favoritos y tampoco hay una vista que los muestre.

Mapa:

```
        1. Inicio --(toca un libro)--> 2. Detalle
        1. Inicio --(botón Favoritos)--> 3. Favoritos
        3. Favoritos --(toca un libro)--> 2. Detalle
        2. Detalle / 3. Favoritos --(botón back)--> pantalla anterior
```

Desde el detalle y desde Favoritos se regresa con el botón *back*.

------------------------------------------------------------------------------------------------------------------------------------------------

### 2. Información por pantalla ###

**Pantalla 1 · Inicio**

| **Muestra** | Título, campo de búsqueda y, por cada libro: portada, título, autor, año y género |
| **Recibe** | La lista de libros |
| **Modifica** | El texto de búsqueda |
| **Necesita conservar** | La lista de libros y los favoritos (para marcar los ya guardados). El texto de búsqueda debe mantenerse al ir al detalle y volver |

**Pantalla 2 · Detalle**

| **Muestra** | Portada, título, autor, botón Guardar, descripción, año y género |
| **Recibe** | El libro seleccionado |
| **Modifica** | Si el libro está guardado o no |
| **Necesita conservar** | El estado de favorito. No debe perderse al salir de la pantalla (hoy sí se pierde) |

**Pantalla 3 · Favoritos (propuesta)**

| **Muestra** | Los libros guardados, o un mensaje de que aún no hay favoritos |
| **Recibe** | La lista de favoritos |
| **Modifica** | Puede quitar libros de favoritos |
| **Necesita conservar** | Los favoritos, que deben coincidir con lo que se ve en Inicio y Detalle |

------------------------------------------------------------------------------------------------------------------------------------------------

### 3. Organización del estado ###

**Single Source of Truth.** Cada dato tiene un solo dueño. Las demás vistas lo leen o lo editan a través de ese dueño, pero no guardan su propia copia.

**Estados identificados**:

| Estado | Dónde se usa | ¿Aplica al MVP? |

| Contenido | Lista y detalle | Sí |
| Selección | Libro elegido en la lista | Sí |
| Filtro | Texto de búsqueda | Sí |
| Favoritos | Detalle, Inicio y Favoritos | Sí |
| Loading | Carga de libros | No por ahora: los datos son locales |
| Error | Falla al cargar | No por ahora: los datos son locales |

**Problemas del código actual**

1. Favoritos mal ubicados: `@State var saved` está dentro de `SecondView`, así que se reinicia cada vez que se sale del detalle, y ni Inicio ni Favoritos pueden saber qué se guardó. Es el problema principal.
2. Una fuente de verdad duplicada en potencia: Si cada pantalla guardara su propia copia de los favoritos, se desincronizarían.
3. Datos y modelo dentro de una vista: `Book` y `books` están en `ContentView.swift`; conviene sacarlos de la vista.
4. Navegación con `NavigationView`: Se propone pasar a `NavigationStack`, que es lo que vimos en clase.

**Dónde debe vivir cada dato**

| Dato | Dónde vive | Herramienta | Por qué |

| Texto de búsqueda | `ContentView` | `@State` | Es estado local: solo importa en Inicio |
| Lista de libros | Objeto compartido (`BookStore`) | `@Observable` | Más de una pantalla la necesita; debe vivir por encima de una vista |
| Favoritos | `BookStore` | `@Observable` | Los leen y modifican tres pantallas; con una sola fuente no se desincronizan |
| Acceso al `BookStore` | Raíz de la app | `@Environment` | Todas las vistas lo usan sin pasarlo manualmente |
| Libro seleccionado | Se envía al navegar | `navigationDestination` | Es información que se pasa entre pantallas, no estado que haya que guardar |

**Uso de @Binding y @Bindable**

- `@Binding`: si el campo de búsqueda se separa en una subvista, esta recibe el texto del padre y lo lee y escribe, en lugar de tener uno propio. Así no hay datos duplicados.
- `@Bindable`: no se necesita en el MVP porque los libros no se editan. Se usaría si más adelante se editaran propiedades de un objeto observable.

**Qué debe mantenerse durante la navegación**

        - Favoritos: siempre, porque viven en el `BookStore` y no en una vista.
        - Texto de búsqueda: al volver del detalle, la lista debe seguir filtrada.
        - Libro seleccionado: solo mientras el detalle está en pantalla.

Cuando el usuario toca "Guardar", cambia el dato en el `BookStore` y SwiftUI actualiza la interfaz en Inicio, Detalle y Favoritos automáticamente.

Los favoritos no se conservan al cerrar la app. Eso queda fuera del MVP.

------------------------------------------------------------------------------------------------------------------------------------------------

### 4. Estrategia de navegación ###

Se propone usar `NavigationStack` con `NavigationLink` y `navigationDestination`.

| Desde | Hacia | Acción | Mecanismo |

| Inicio | Detalle | Toca un libro | `NavigationLink` + `navigationDestination` |
| Detalle | Inicio | Botón *back* | Automático con `NavigationStack` |
| Inicio | Favoritos | Botón de Favoritos | `NavigationLink` |
| Favoritos | Detalle | Toca un libro | El mismo `navigationDestination` |
| Detalle | Detalle | Guardar | El botón modifica el dato del `BookStore` |

Por qué esta opción:

- Inicio no necesita saber cómo se construye el detalle: solo envía el libro elegido.
- El mismo destino sirve para llegar al detalle desde Inicio y desde Favoritos, sin duplicar código.

------------------------------------------------------------------------------------------------------------------------------------------------

### 5. Plan de implementación ###

Lo que se haría en la siguiente etapa, ordenado por tema visto en clase.

**Estado**

- [ ] Crear el `BookStore` con `@Observable`, con la lista de libros y los favoritos
- [ ] Inyectarlo en la raíz de la app con `@Environment`
- [ ] Quitar `@State var saved` de `SecondView` y usar el dato del `BookStore`
- [ ] Mantener `searchText` como `@State` en `ContentView`

**Navegación**

- [ ] Cambiar `NavigationView` por `NavigationStack`
- [ ] Usar `NavigationLink` y `navigationDestination` para ir al detalle
- [ ] Crear `FavoritesView` y agregar el acceso desde Inicio

**Componentes**

- [ ] Mover `Book` a su propio archivo
- [ ] Extraer la fila del libro (`BookRow`) como subvista, porque el mismo diseño se repite

**Interfaz adaptativa y accesibilidad**

- [ ] Revisar los tamaños fijos de las portadas (`frame` de 60×80 y 120×170) para que se adapten
- [ ] Probar con Dynamic Type
- [ ] Agregar labels descriptivos para VoiceOver (portada y botón Guardar)
- [ ] No depender solo del color: año y género van solo en rojo y en letra pequeña
- [ ] Mostrar un mensaje cuando la búsqueda no tenga resultados y cuando no haya favoritos
