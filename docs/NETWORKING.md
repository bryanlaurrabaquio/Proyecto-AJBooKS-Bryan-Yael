# Networking: Open Library

BYbooKS obtiene sus datos de la API REST pública de **Open Library** (Internet Archive).
Toda la comunicación está en `Services/BookService.swift` (`OpenLibraryService`); las vistas no hacen peticiones.

## 1. Servicio y configuración

| Concepto | Valor |
|---|---|
| API | Open Library — Search API, Works/Editions API y Covers API |
| URL base | `https://openlibrary.org` (datos) y `https://covers.openlibrary.org` (portadas) |
| Autenticación | **No requiere API Key** ni credenciales |
| Formato | JSON en UTF-8 (portadas en JPEG) |
| Cabeceras enviadas | `Accept: application/json`, `User-Agent: BYbooKS/1.0 (proyecto educativo)` |
| Tiempo de espera | 15 s por petición |
| Documentación oficial | https://openlibrary.org/developers/api |

No hay nada que configurar para ejecutar la app. Si en el futuro se usa un servicio con clave, la clave no debe
escribirse en el código ni subirse al repositorio (usar un archivo `.xcconfig` local excluido en `.gitignore`).

## 2. Endpoints

| Uso | Método y ruta | Parámetros importantes |
|---|---|---|
| Catálogo | `GET /search.json` | `q`, `fields`, `lang`, `limit` |
| Descripción de la edición | `GET /books/{OLID}.json` (ej. `/books/OL60608500M.json`) | — |
| Descripción de la obra | `GET /works/{OLID}.json` (ej. `/works/OL498434W.json`) | — |
| Portada | `GET https://covers.openlibrary.org/b/id/{cover_i}-{S\|M\|L}.jpg?default=false` | tamaño `S`, `M` (tarjetas) o `L` (detalle) |

### Parámetros de la búsqueda

| Parámetro | Valor | Para qué |
|---|---|---|
| `q` | `subject:classics language:spa` | Clásicos que tienen al menos una edición en español. `subject:classics` viene de `BookListViewModel.featuredQuery`; el servicio agrega `language:spa`. |
| `lang` | `es` | Hace que `editions` devuelva, para cada obra, la edición en español. |
| `fields` | `key,title,author_name,first_publish_year,subject,cover_i,editions,editions.key,editions.title,editions.language,editions.cover_i` | Solo los campos que usa la app (respuesta más pequeña). |
| `limit` | `20` | Número de libros del catálogo. |

Ejemplo de URL generada:

```
https://openlibrary.org/search.json?q=subject:classics%20language:spa&fields=key,title,author_name,first_publish_year,subject,cover_i,editions,editions.key,editions.title,editions.language,editions.cover_i&lang=es&limit=20
```

## 3. Formato de las respuestas

Búsqueda (recortada, respuesta real):

```json
{
  "numFound": 2693,
  "docs": [
    {
      "key": "/works/OL498434W",
      "title": "Das Schloß",
      "author_name": ["Franz Kafka"],
      "first_publish_year": 1926,
      "cover_i": 12605605,
      "subject": ["Fiction", "Bureaucracy", "Castles"],
      "editions": {
        "numFound": 11,
        "docs": [
          { "key": "/books/OL60608500M", "title": "El castillo", "cover_i": 15140518, "language": ["spa"] }
        ]
      }
    }
  ]
}
```

Obra o edición: la descripción llega como texto o como objeto, según el registro:

```json
{ "description": "texto..." }
{ "description": { "type": "/type/text", "value": "texto..." } }
```

## 4. Modelos y decodificación

`JSONDecoder` con `keyDecodingStrategy = .convertFromSnakeCase` (`author_name` → `authorName`, `cover_i` → `coverI`).

| DTO (`Models/OpenLibraryDTO.swift`) | Campos | Se convierte en |
|---|---|---|
| `OpenLibrarySearchResponse` | `docs` | `[Book]` |
| `OpenLibraryDocument` | `key`, `title`, `authorName`, `firstPublishYear`, `subject`, `coverI`, `editions` | `Book` mediante `toBook()` |
| `OpenLibraryEdition` | `key`, `title`, `language`, `coverI` | Título, portada y `editionKey` |
| `OpenLibraryRecord` / `OpenLibraryText` | `description` (texto u objeto) | Texto limpio (`cleanedDescription`) |

Reglas de `OpenLibraryDocument.toBook()`:

| Dato de `Book` | Regla |
|---|---|
| `id` | `key` de la obra (`/works/OL…W`). Es estable: se usa para favoritos. |
| `title` | Título de la edición en español; si no existe, el título original. Nunca se traduce un título. |
| `author` | Nombres limpios, sin duplicados, unidos con coma. No se traducen ni se reordenan. Sin autor: "Autor desconocido". |
| `year` | `first_publish_year` (año de la primera publicación de la obra). |
| `genre` | `SubjectGenreMapper`: primera categoría conocida, por prioridad (género literario > tema de no ficción > general > público). |
| `coverID` | Portada de la edición en español; si no tiene, la de la obra. `-1` o ausente = sin portada. |
| `editionKey` | Clave de la edición mostrada, para pedir su descripción. |

Los documentos sin título se descartan.

## 5. Descripciones

La búsqueda no incluye descripciones. Se piden cuando la tarjeta aparece en pantalla o al abrir el detalle:

1. `GET /books/{edición}.json`. Si su descripción está en español, se usa y **no** se consulta la obra.
2. Si no, `GET /works/{obra}.json`.
3. `BookDescription.select` decide el resultado:
   - Descripción en español (edición primero, luego obra) → `.spanish(texto)`.
   - Solo en otro idioma → `.otherLanguage(texto, código)`: la tarjeta dice "Descripción disponible solo en inglés"
     y el detalle ofrece **Traducir al español** con el framework Translation de iOS (en el dispositivo, sin
     credenciales). Se avisa que es una traducción automática, no una sinopsis oficial.
   - Nada utilizable → `.unavailable`: "Descripción no disponible".

El idioma se detecta con `NLLanguageRecognizer` (framework NaturalLanguage). Los textos de menos de 60 caracteres
se ignoran porque en Open Library suelen ser créditos ("Edición de …"), no descripciones.

En una muestra de 40 clásicos con edición en español (noviembre de 2026), solo 5 tenían descripción en español en
Open Library; las demás solo estaban en inglés. Es una limitación de la fuente, no de la app.

## 6. Limpieza de texto (`TextSanitizer`)

Se aplica al convertir el JSON al modelo, nunca en las vistas:

| Problema | Ejemplo | Resultado |
|---|---|---|
| Entidades HTML | `Pride &amp; Prejudice` | `Pride & Prejudice` |
| Etiquetas HTML | `<i>El</i> Aleph`, `<br>` | `El Aleph`, salto de línea |
| Texto mal codificado | `CorazÃ³n`, `Â¿DÃ³nde?` | `Corazón`, `¿Dónde?` |
| Markdown | `***Heidi***`, `[texto](url)`, `[1]: https://…` | `Heidi`, `texto`, (se elimina) |
| Caracteres invisibles o de reemplazo | `U+200B`, `U+FEFF`, `U+FFFD` | Se eliminan |
| Espacios y saltos | `\r\n\r\n\r\n`, espacios duros | Un salto de párrafo, un espacio |
| Puntuación de catálogo en títulos | `La Odisea.`, `El castillo /` | `La Odisea`, `El castillo` |
| Acentos descompuestos | `a` + `◌́` | `á` (normalización NFC) |

Se conservan acentos, ñ, ¿, ¡, comillas tipográficas, guiones y puntos suspensivos.

## 7. Portadas

`OpenLibraryCovers.url(coverID:size:)` arma la URL. Con `default=false`, si la portada no existe el servidor
responde 404 en lugar de una imagen en blanco, y `BookCoverView` muestra la portada de respaldo de BYbooKS.
`BookCoverView` usa `AsyncImage` con sus cuatro fases (cargando, imagen, error y estado futuro desconocido),
proporción fija 2:3 y `scaledToFill` recortado, de modo que la imagen nunca se deforma.
La app amplía `URLCache.shared` (30 MB en memoria, 150 MB en disco) para no descargar las portadas otra vez.

## 8. Manejo de errores

Cada petición sigue los mismos pasos: construir la `URLRequest`, descargar con `URLSession` (`async/await`),
validar que la respuesta sea `HTTPURLResponse` con código 200–299 y decodificar con `JSONDecoder`.

| `BookServiceError` | Cuándo | Mensaje |
|---|---|---|
| `.invalidURL` | No se pudo construir la URL | "No se pudo preparar la consulta." |
| `.connectivity` | `URLError` (sin red, tiempo agotado…) | "No hay conexión con Open Library." + "Revisa tu conexión a internet e inténtalo de nuevo." |
| `.invalidResponse` | La respuesta no es HTTP | "La respuesta del servidor es inválida." |
| `.httpStatus(429)` | Demasiadas solicitudes | "Open Library recibió demasiadas solicitudes." + "Espera unos segundos…" |
| `.httpStatus(código)` | Otro código fuera de 200–299 | "Error del servidor. Código HTTP: …" |
| `.decoding` | El JSON no tiene la forma esperada | "No se pudieron interpretar los libros." |
| `.unknown` | Cualquier otro error | "Ocurrió un error inesperado." |

- Un 404 al pedir una edición u obra se trata como "sin descripción", no como error.
- La cancelación (`CancellationError` o `URLError.cancelled`) no se muestra como error: el catálogo vuelve a `idle`.
- Un error al cargar una descripción solo afecta a ese libro (`DescriptionState.failed`) y el detalle ofrece *Reintentar*.

## 9. Estados en la interfaz

| Estado | Catálogo (`LoadState`) | Descripción (`DescriptionState`) |
|---|---|---|
| Cargando | `idle` / `loading`: indicador "Cargando libros…" | `idle` / `loading`: línea de carga en la tarjeta, indicador en el detalle |
| Éxito | `content`: tarjetas | `loaded(.spanish)`: resumen en la tarjeta, texto completo en el detalle |
| Vacío | `empty`: "No hay libros para mostrar" + *Volver a consultar* | `loaded(.unavailable)`: "Descripción no disponible" |
| Error | `error`: mensaje, sugerencia y *Reintentar* | `failed`: "No se pudo cargar la descripción" + *Reintentar* |
| Sin coincidencias | Búsqueda local sin resultados: "No se encontraron libros para “…”" | — |

## 10. Pruebas del networking

`HTTPClient` es un protocolo implementado por `URLSession`; las pruebas lo sustituyen por clientes falsos
(`MockHTTPClient`, `RoutingHTTPClient`) para comprobar sin red: decodificación, campos faltantes, respuestas
vacías, errores HTTP, JSON inválido, falta de conexión, el orden edición → obra y la limpieza del texto.
Ver `OpenLibraryServiceTests.swift`, `CatalogMappingTests.swift` y `BookDescriptionTests.swift`.
