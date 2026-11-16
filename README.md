# BYbooKS

**BYbooKS** es una aplicación para iPhone y iPad que permite explorar clásicos universales en ediciones en español,
consultar su portada, descripción y datos principales, y guardar los favoritos en el dispositivo.
Los libros se obtienen de la API pública de [Open Library](https://openlibrary.org).

Proyecto final de la materia **Desarrollo de Aplicaciones iOS** de la **UNAM** — Equipo 8.

| | |
|---|---|
| Plataforma | iOS / iPadOS 26.5 o posterior |
| Interfaz | SwiftUI, modo claro y oscuro |
| Arquitectura | MVVM con fuente única de verdad (`BookStore`) |
| Datos | Open Library (API REST, sin API Key) |
| Persistencia | SwiftData |
| Dependencias externas | Ninguna |

---

## Tabla de contenido

1. [Descripción del problema](#descripción-del-problema)
2. [Funcionalidades](#funcionalidades)
3. [Tecnologías utilizadas](#tecnologías-utilizadas)
4. [Requisitos del sistema](#requisitos-del-sistema)
5. [Instalación y configuración](#instalación-y-configuración)
6. [Ejecución](#ejecución)
7. [Servicios externos](#servicios-externos)
8. [Capturas de pantalla](#capturas-de-pantalla)
9. [Arquitectura](#arquitectura)
10. [Pruebas](#pruebas)
11. [Roadmap](#roadmap)
12. [Limitaciones conocidas](#limitaciones-conocidas)
13. [Integrantes](#integrantes)
14. [Documentación adicional](#documentación-adicional)

---

## Descripción del problema

Quien busca qué leer en español suele encontrar catálogos en inglés, con títulos originales, fichas incompletas o
sin portada, y necesita una cuenta para guardar los libros que le interesan.

BYbooKS está dirigida a **lectores hispanohablantes** y a estudiantes que quieren descubrir clásicos de la
literatura. Permite:

- ver un catálogo de clásicos con **título y portada de la edición en español**;
- buscar rápidamente por título o autor, sin importar acentos ni mayúsculas;
- leer la descripción en español cuando la fuente la tiene, o saber con claridad cuándo no existe;
- guardar favoritos **sin crear una cuenta**, disponibles aunque no haya conexión.

## Funcionalidades

Estado según la revisión de esta versión (ver [Roadmap](#roadmap) para el detalle de lo verificado):

| Funcionalidad | Estado | Detalle |
|---|---|---|
| Catálogo desde una API REST | Completada | 20 clásicos de Open Library con edición en español (`subject:classics language:spa`). |
| Títulos en español | Completada | Se usa el título de la edición en español; si no existe se conserva el original (no se inventan traducciones). |
| Portadas | Completada | `AsyncImage` con estados de carga, imagen, error y portada de respaldo de BYbooKS; proporción 2:3 sin deformar. |
| Descripciones | Parcial | Se muestra la descripción en español cuando Open Library la tiene (edición o, si no, obra). Open Library casi nunca la tiene en español: en ese caso se avisa y se ofrece la traducción automática de iOS a petición. |
| Limpieza de texto | Completada | Sin entidades HTML, etiquetas, Markdown, caracteres extraños ni espacios sobrantes. |
| Géneros en español | Completada | Los temas de Open Library se traducen con un vocabulario controlado; si no hay coincidencia no se muestra género. |
| Búsqueda | Parcial | Filtra los libros descargados por título o autor (sin distinguir acentos ni mayúsculas). No consulta la API. |
| Detalle del libro | Completada | Portada grande, autor, año, género, descripción completa y botón para guardar. |
| Favoritos | Completada | Guardar y quitar desde la tarjeta, el detalle o la pantalla de Favoritos; contador en Inicio. |
| Persistencia local | Completada | SwiftData; los favoritos se conservan al cerrar la app. |
| Navegación | Completada | `NavigationStack` con navegación por valor (Inicio → Detalle, Inicio → Favoritos → Detalle). |
| Estados de la interfaz | Completada | Cargando, contenido, vacío, sin coincidencias y error de conexión con *Reintentar*. |
| Modo claro y oscuro | Completada | Paleta editorial con variantes para ambos modos y contraste WCAG AA. |
| Accesibilidad | Parcial | Dynamic Type, etiquetas de VoiceOver, áreas táctiles de 44 pt. Falta una auditoría manual con VoiceOver. |
| Búsqueda en Open Library, paginación, ícono | Pendiente | Ver [Roadmap](#roadmap). |

## Tecnologías utilizadas

| Tecnología | Uso en el proyecto |
|---|---|
| **Swift** | Lenguaje (modo de lenguaje Swift 5, `SWIFT_VERSION = 5.0`; aislamiento por defecto en `MainActor`). |
| **SwiftUI** | Toda la interfaz. |
| **MVVM** | Un ViewModel por pantalla y `BookStore` como fuente única de verdad. |
| **Observation** | `@Observable` en `BookStore` y ViewModels; `@Bindable` y `@Binding` para la búsqueda. |
| **SwiftData** | Persistencia de favoritos (`@Model FavoriteBook`, `ModelContainer`, `#Predicate`). |
| **Foundation** | `URLSession`, `URLRequest`, `HTTPURLResponse`, `JSONDecoder`, `URLCache`. |
| **async/await** | Peticiones de red y carga de descripciones. |
| **API REST** | Open Library: Search, Works/Editions y Covers. |
| **NaturalLanguage** | Detecta si una descripción está en español. |
| **Translation** | Traducción del sistema, en el dispositivo, a petición del usuario. |
| **XCTest y Swift Testing** | Pruebas unitarias. |
| **XCUITest** | Pruebas de interfaz. |
| **Git y GitHub** | Control de versiones. |

## Requisitos del sistema

Valores tomados de la configuración del proyecto (`project.pbxproj`) y de la
[tabla oficial de requisitos de Xcode](https://developer.apple.com/support/xcode/):

| Requisito | Versión |
|---|---|
| macOS | macOS Tahoe 26.2 o posterior (requisito de Xcode 26.5 y 26.6) |
| Xcode | 26.5 o posterior (el proyecto se creó con Xcode 26.6) |
| SDK de iOS | iOS 26.5 |
| Swift | Compilador Swift 6.3 incluido en Xcode 26.5/26.6; el código necesita al menos Swift 6.2 y usa el modo de lenguaje Swift 5 |
| iOS / iPadOS | 26.5 o posterior (`IPHONEOS_DEPLOYMENT_TARGET = 26.5`) |
| Dispositivos | iPhone y iPad (`TARGETED_DEVICE_FAMILY = 1,2`) |
| Red | Conexión a internet para el catálogo, las portadas y las descripciones |

## Instalación y configuración

1. **Obtener el repositorio**

   ```bash
   git clone https://github.com/bryanlaurrabaquio/Proyecto-AJBooKS-Bryan-Yael.git
   ```

   ```bash
   cd Proyecto-AJBooKS-Bryan-Yael
   ```

   Si los cambios de esta versión están en una rama distinta de la principal, cámbiate a ella, por ejemplo:

   ```bash
   git switch Practica7Correcciones
   ```

2. **Abrir el proyecto en Xcode**

   ```bash
   open "Proyecto Bry y Yael.xcodeproj"
   ```

   O desde Xcode: *File → Open…* y elegir `Proyecto Bry y Yael.xcodeproj`.

3. **Revisar las dependencias.** No hay paquetes de Swift Package Manager ni CocoaPods: solo frameworks de Apple.
   No hay que descargar nada adicional.

4. **Configurar servicios externos.** Open Library no requiere API Key. No hay que crear archivos de configuración
   ni variables de entorno.

5. **Seleccionar el destino.** En la barra superior de Xcode, elige el esquema **Proyecto Bry y Yael** y un
   simulador de iPhone con iOS 26.5 o posterior. Para un iPhone físico: conéctalo, actívale el *Modo de
   desarrollador* y, en *Signing & Capabilities* del target, elige tu *Team* (Apple ID).

6. **Preparar el entorno.** Si Xcode pide instalar el componente de la plataforma iOS 26.5, acepta la descarga
   (*Xcode → Settings → Components*).

## Ejecución

1. Abre el proyecto y selecciona el esquema **Proyecto Bry y Yael**.
2. Elige un simulador o dispositivo.
3. Compila y ejecuta con **⌘R** (*Product → Run*).
4. La app abre en **Inicio**, carga el catálogo de Open Library y, al desplazarse, carga portadas y descripciones.
5. Para ejecutar las pruebas: **⌘U** (*Product → Test*).

> **Nota:** la traducción automática (*Traducir al español*) usa el framework Translation de iOS. Puede no estar
> disponible en el simulador; pruébala en un iPhone. La primera vez, iOS puede pedir descargar el idioma.

### Trabajar desde Windows

- Editar archivos `.swift` en VS Code o en un IDE de JetBrains **no** equivale a compilar la app: compilar,
  ejecutar en el simulador y correr las pruebas de una app iOS requiere **macOS y Xcode**.
- El toolchain de Swift para Windows puede compilar código que solo usa Foundation, pero no SwiftUI, SwiftData,
  UIKit, NaturalLanguage ni Translation.
- Flujo recomendado: editar en Windows, subir la rama y compilar/probar en una Mac con Xcode antes de entregar.

## Servicios externos

| | |
|---|---|
| Servicio | [Open Library API](https://openlibrary.org/developers/api) (Internet Archive) |
| URL base | `https://openlibrary.org` y `https://covers.openlibrary.org` |
| Autenticación | No requiere API Key |
| Formato | JSON (UTF-8); portadas en JPEG |

| Endpoint | Para qué | Parámetros importantes |
|---|---|---|
| `GET /search.json` | Catálogo | `q=subject:classics language:spa`, `lang=es`, `fields=…`, `limit=20` |
| `GET /books/{id}.json` | Descripción de la edición | — |
| `GET /works/{id}.json` | Descripción de la obra | — |
| `GET /b/id/{cover_i}-{S\|M\|L}.jpg?default=false` | Portadas | Tamaño `M` en tarjetas y `L` en el detalle |

**Configuración segura:** la app no usa credenciales. Si en el futuro se integra un servicio con clave, no debe
escribirse en el código ni subirse a GitHub: usar un archivo de configuración local excluido con `.gitignore`.

Detalles de respuestas, modelos, decodificación y errores: [docs/NETWORKING.md](docs/NETWORKING.md).

## Capturas de pantalla

Las capturas de la versión actual **todavía no están incluidas**: esta revisión se hizo sin acceso a una Mac con
Xcode, por lo que no se generaron capturas (no se usan imágenes simuladas como evidencia).
La guía [docs/screenshots/README.md](docs/screenshots/README.md) indica cómo tomarlas y qué nombre darles.

| Captura pendiente | Pantalla |
|---|---|
| `01-inicio-claro.png` / `02-inicio-oscuro.png` | Inicio con catálogo, modo claro y oscuro |
| `03-busqueda.png` / `04-sin-resultados.png` | Búsqueda con y sin coincidencias |
| `05-detalle-espanol.png` | Detalle con descripción en español |
| `06-detalle-solo-ingles.png` / `07-traduccion-sistema.png` | Aviso de descripción solo en inglés y traducción de iOS |
| `08-favoritos.png` / `09-favoritos-vacio.png` | Favoritos con libros y vacío |
| `10-error-conexion.png` | Error de conexión con *Reintentar* |
| `11-dynamic-type.png` | Texto de accesibilidad grande |

Los bocetos de `docs/wireframes/` corresponden al diseño inicial (cuando la app se llamaba AJBooks) y no
representan la interfaz actual.

## Arquitectura

```
View (SwiftUI)  ──acciones──▶  ViewModel  ──▶  BookStore (fuente única de verdad)
      ▲                           │                 │            │
      └──── estado observable ────┘                 ▼            ▼
                                        OpenLibraryService   FavoritesService
                                        (URLSession, JSON)   (SwiftData)
```

- **Model:** `Book`, `BookDescription`, `FavoriteBook`, `LoadState`, `BookStore` y los DTO de Open Library.
- **View:** `ContentView` (Inicio), `SecondView` (Detalle), `FavoritesView` y componentes reutilizables.
- **ViewModel:** `BookListViewModel`, `BookDetailViewModel`, `FavoritesViewModel`.
- **Service:** `OpenLibraryService`, `FavoritesService`, `TextSanitizer`, `LanguageDetector`, `SubjectGenreMapper`.

Los identificadores internos (target `Proyecto Bry y Yael`, módulo `Proyecto_Bry_y_Yael`, bundle ID
`fca.Proyecto-Bry-y-Yael`) se conservan a propósito para no romper las pruebas ni los favoritos ya guardados;
el nombre visible en el iPhone es **BYbooKS**. Explicación completa en [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Pruebas

| Archivo | Tipo | Pruebas | Qué cubre |
|---|---|---|---|
| `Proyecto_Bry_y_YaelTests.swift` | Swift Testing | 15 | Modelo, búsqueda (acentos y mayúsculas), ViewModels, favoritos |
| `TextSanitizerTests.swift` | Swift Testing | 14 | Entidades HTML, Markdown, codificación, Unicode, títulos |
| `CatalogMappingTests.swift` | Swift Testing | 14 | Edición en español, portadas, géneros, petición de búsqueda, decodificación |
| `BookDescriptionTests.swift` | Swift Testing | 25 | Selección de descripción, idioma, servicio edición → obra, `BookStore`, presentación |
| `OpenLibraryServiceTests.swift` | XCTest | 12 | Decodificación, errores HTTP, JSON inválido, conectividad, reintento |
| `BookStoreFavoritesTests.swift` | XCTest | 6 | Favoritos a través del servicio |
| `FavoritesServiceTests.swift` | XCTest + SwiftData | 8 | Persistencia real en memoria, sin duplicados, portada guardada |
| `PaletteTests.swift` | XCTest + UIKit | 2 | Los colores existen y tienen variante oscura |
| `Proyecto_Bry_y_YaelUITests.swift` y `…LaunchTests.swift` | XCUITest | 4 | Arranque, marca, buscador y acceso a Favoritos |

Ejecutar en Xcode con **⌘U**. Ninguna prueba unitaria usa la red.

**Verificación de esta revisión:** la capa de lógica (Model, Services, ViewModels) se compiló y probó en Linux
con Swift 6.2.3 replicando los ajustes del proyecto: 68 pruebas de Swift Testing y 18 de XCTest aprobadas, sin
advertencias del compilador en el código del proyecto. La sintaxis de todos los archivos Swift (incluidas las
vistas) se validó con el analizador de Swift. No se ejecutaron en este entorno las pruebas que dependen de SwiftData, UIKit o del simulador
(`FavoritesServiceTests`, `PaletteTests` y las de interfaz), ni se compilaron las vistas SwiftUI: deben
comprobarse en Xcode.

## Roadmap

### Completado

- [x] Arquitectura MVVM con `BookStore` como fuente única de verdad.
- [x] Navegación con `NavigationStack` y navegación por valor.
- [x] Catálogo desde Open Library con `URLSession`, `async/await`, validación HTTP y `JSONDecoder`.
- [x] Estados de carga, contenido, vacío, sin coincidencias y error con reintento.
- [x] Favoritos persistentes con SwiftData.
- [x] Títulos y portadas de la edición en español (verificado contra la API real: 20 de 20 libros con portada).
- [x] Limpieza de texto y géneros en español (cubiertos por pruebas unitarias).
- [x] Nombre comercial **BYbooKS**.

### En desarrollo

- [ ] Verificar en Xcode la nueva interfaz: tarjetas, paleta, modo claro/oscuro y portadas (código escrito y
      revisado; falta compilarlo y revisarlo visualmente).
- [ ] Descripciones: la lógica está probada; la traducción del sistema debe probarse en un iPhone.
- [ ] Accesibilidad: implementada; falta auditoría con VoiceOver y Accessibility Inspector.
- [ ] Capturas de pantalla de la versión actual.

### Pendiente

- [ ] Búsqueda directa en Open Library (hoy la búsqueda filtra los libros descargados).
- [ ] Más resultados con paginación.
- [ ] Guardar el catálogo y las descripciones para consultarlos sin conexión.
- [ ] Ícono de la app (el `AppIcon` está vacío).
- [ ] Ordenar favoritos por fecha de guardado o por título.
- [ ] Renombrar `ContentView` → `BookListView` y `SecondView` → `BookDetailView` (pendiente desde la Práctica 5).
- [ ] Catálogo de cadenas (*String Catalog*) para centralizar los textos de la interfaz.

## Limitaciones conocidas

- **Descripciones en español:** Open Library tiene muy pocas. En una muestra de 40 clásicos con edición en
  español, solo 5 la tenían en español; el resto solo en inglés. La app no inventa ni traduce sinopsis por su
  cuenta: avisa y ofrece la traducción automática de iOS, señalada como no oficial.
- **Traducción del sistema:** depende del framework Translation; puede no funcionar en el simulador y puede pedir
  descargar el idioma.
- **Datos de la fuente:** algunos títulos de ediciones en español conservan el original o mezclan idiomas
  (*Of Mice and Men*, *LA Mitologia/Mythology*); algunos autores aparecen en su escritura original
  (*Ὅμηρος*) o invertidos (*Spyri, Johanna*). Se muestran como los entrega Open Library.
- **Año:** es el de la primera publicación de la obra según Open Library y puede no coincidir con la edición mostrada.
- **Búsqueda local:** solo busca entre los 20 libros descargados.
- **Límite de solicitudes:** cada tarjeta pide hasta dos registros a Open Library; si el servidor responde 429,
  la descripción muestra un aviso y se puede reintentar desde el detalle.
- **Favoritos:** solo en el dispositivo (sin iCloud); los guardados antes de esta versión no tienen portada
  hasta que se vuelven a guardar. Sin conexión no se muestran descripciones.
- **Verificación pendiente en Xcode:** las vistas SwiftUI y las pruebas de SwiftData, UIKit e interfaz no se
  ejecutaron en esta revisión (ver [Pruebas](#pruebas)).

## Integrantes

- **Bryan Ricardo Laurrabaquio Ramírez**
- **Yael Alam González Próspero**

## Documentación adicional

| Documento | Contenido |
|---|---|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Carpetas, responsabilidades, flujo de datos, estado, diseño, accesibilidad y decisiones técnicas |
| [docs/NETWORKING.md](docs/NETWORKING.md) | API, endpoints, modelos, decodificación, limpieza de texto y errores |
| [docs/PERSISTENCE.md](docs/PERSISTENCE.md) | SwiftData, modelo de favoritos, migración y limitaciones |
| [docs/screenshots/README.md](docs/screenshots/README.md) | Guía para tomar las capturas |
| [docs/mvvm-investigacion-arquitectura.md](docs/mvvm-investigacion-arquitectura.md) | Histórico: investigación previa a MVVM |
| [docs/mvvm-refactorizacion.md](docs/mvvm-refactorizacion.md) | Histórico: refactorización a MVVM (Práctica 5) |
| [docs/navigation-and-state.md](docs/navigation-and-state.md) | Histórico: navegación y estado del MVP |

Datos y portadas: [Open Library](https://openlibrary.org), un proyecto de Internet Archive.
