# Capturas de pantalla de BYbooKS

Esta carpeta debe contener **capturas reales** de la versión actual, tomadas en Xcode con el simulador o un
iPhone. Las imágenes de `docs/wireframes/` son bocetos del diseño inicial (con el nombre anterior, AJBooks)
y no representan la app actual.

## Cómo tomarlas

1. Ejecuta la app en un simulador de iPhone con iOS 26.5 o posterior (⌘R).
2. En el simulador: **File → Save Screen** (⌘S); la imagen se guarda en el Escritorio.
   También se puede usar la terminal: `xcrun simctl io booted screenshot nombre.png`.
3. Para el modo oscuro: **Features → Toggle Appearance** (⇧⌘A).
4. Para Dynamic Type: Xcode → **Open Developer Tool → Accessibility Inspector**, o en el simulador
   *Ajustes → Accesibilidad → Pantalla y tamaño de texto → Texto más grande*.
5. Guarda cada imagen en esta carpeta con el nombre exacto de la tabla.

## Pantallas necesarias

| Archivo | Pantalla | Cómo llegar |
|---|---|---|
| `01-inicio-claro.png` | Inicio con el catálogo cargado, modo claro | Abrir la app y esperar a que carguen portadas y descripciones |
| `02-inicio-oscuro.png` | Inicio, modo oscuro | ⇧⌘A en el simulador |
| `03-busqueda.png` | Búsqueda con resultados | Escribir `castillo` o `Kafka` |
| `04-sin-resultados.png` | Búsqueda sin coincidencias | Escribir `zzzz` |
| `05-detalle-espanol.png` | Detalle con descripción en español | Abrir *El Arte de la Guerra completo* (si sigue en el catálogo) |
| `06-detalle-solo-ingles.png` | Detalle con el aviso de descripción solo en inglés y el botón *Traducir al español* | Abrir *El castillo* |
| `07-traduccion-sistema.png` | Hoja de traducción de iOS | Tocar *Traducir al español* (**en un iPhone físico**: la traducción puede no estar disponible en el simulador) |
| `08-favoritos.png` | Favoritos con 2 o más libros | Tocar el corazón de dos tarjetas y abrir Favoritos |
| `09-favoritos-vacio.png` | Favoritos vacío | Quitar todos los favoritos |
| `10-error-conexion.png` | Error de conexión con *Reintentar* | Desactivar la red del Mac (o usar Network Link Conditioner) y reiniciar la app |
| `11-dynamic-type.png` | Inicio con texto de accesibilidad grande | Tamaño de texto *AX3* o mayor |

El catálogo viene de Open Library y puede cambiar con el tiempo; si un libro mencionado ya no aparece, usa
otro con el mismo tipo de descripción.

## Galería para el README

Cuando las imágenes existan, sustituye la tabla de la sección *Capturas de pantalla* del README por:

```html
<p float="left">
  <img src="docs/screenshots/01-inicio-claro.png" width="230" alt="Inicio de BYbooKS en modo claro" />
  <img src="docs/screenshots/02-inicio-oscuro.png" width="230" alt="Inicio de BYbooKS en modo oscuro" />
  <img src="docs/screenshots/05-detalle-espanol.png" width="230" alt="Detalle con descripción en español" />
  <img src="docs/screenshots/06-detalle-solo-ingles.png" width="230" alt="Detalle con opción de traducción" />
  <img src="docs/screenshots/08-favoritos.png" width="230" alt="Favoritos guardados" />
  <img src="docs/screenshots/10-error-conexion.png" width="230" alt="Error de conexión con botón Reintentar" />
</p>
```
