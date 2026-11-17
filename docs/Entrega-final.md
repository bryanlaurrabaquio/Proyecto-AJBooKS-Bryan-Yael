# Entrega final — Práctica 8

**Equipo 8:** Yael Alam González Prospero · Bryan Ricardo Laurrabaquio Ramírez

## 1. Versión de entrega

| Dato | Valor |
|---|---|
| Rama | `<rama>` |
| Commit final | `<hash del commit>` |
| Etiqueta (opcional) | `<v1.0>` |

## 2. Revisión del repositorio

| Punto de revisión | Resultado |
|---|---|
| Claves, tokens o credenciales en el código | No hay. Open Library es pública y no requiere autenticación |
| Archivos de configuración necesarios | No hay: la app no usa archivos de configuración ni dependencias externas |
| Archivos temporales | Se agregó `.gitignore` (`.DS_Store`, `xcuserdata/`, `DerivedData/`, `.idea/`, etc.). La carpeta `.idea/` se quitó del repositorio |
| Código de depuración | Se eliminó el `print` que mostraba cuántos libros llegaban de la API (`BookService.swift`). Se conservan los `print` que registran errores de SwiftData |
| Código de ejemplo | `Book+Samples.swift` está dentro de `#if DEBUG`: solo se usa en vistas previas y no entra en la app final |
| Nombres y organización | El código está separado en `Models`, `Services`, `ViewModels` y `Views`. El nombre de la app es **BYbooKS** en todo el código y la documentación (solo las imágenes de los wireframes conservan el nombre anterior) |
| Documentación vs. implementación | El README se reescribió. Los documentos de las prácticas 4 y 5 se actualizaron a la versión final y se creó `documentacion-tecnica.md` con lo realmente implementado |
| Capturas de pantalla | Agregadas en `docs/screenshots/` |

## 3. Funcionalidades del MVP verificadas

Marcar después de probarlas en el simulador.

- [ ] Al abrir la app se carga el catálogo de libros en tendencia
- [ ] Jalar la lista hacia abajo cambia los libros por otros
- [ ] Escribir en el campo filtra los libros descargados por título o autor
- [ ] Presionar *Buscar* consulta Open Library y muestra los resultados
- [ ] Buscar algo inexistente muestra el mensaje de "sin resultados"
- [ ] Con el modo avión activado se muestra el error con *Reintentar*, y al reconectar funciona
- [ ] Tocar un libro abre el detalle con portada, autor, año, género y descripción
- [ ] *Guardar* marca el libro y el contador del corazón sube
- [ ] El libro guardado aparece en Favoritos
- [ ] Cerrar la app por completo y volver a abrirla conserva los favoritos
- [ ] *Guardado* en el detalle quita el libro de Favoritos
- [ ] Favoritos vacío muestra "Aún no tienes libros favoritos"
- [ ] Con modo avión, Favoritos sigue mostrando los libros guardados

## 4. Pruebas ejecutadas

| Dato | Valor |
|---|---|
| Comando o forma de ejecución | ⌘U en Xcode (o `xcodebuild test`, ver README) |
| Simulador / iOS | `<modelo y versión>` |
| Pruebas unitarias | `<pasaron X de Y>` |
| Fecha | `<fecha>` |

Las pruebas unitarias son 30 de XCTest y 15 de Swift Testing; no usan la red real. Las pruebas de interfaz son solo la plantilla de Xcode.

## 5. Limitaciones y pendientes

Ver [`documentacion-tecnica.md`, sección 8](documentacion-tecnica.md#8-limitaciones-conocidas). Las principales:

- Sin conexión, los favoritos no muestran portada ni descripción.
- En Favoritos no se puede quitar un libro: se hace desde el detalle.
- La búsqueda trae un máximo de 50 resultados, sin paginación.
- Las portadas tienen tamaño fijo y no escalan con Dynamic Type.
- No hay pruebas de interfaz propias.
