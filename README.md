# Proyecto-AJBooKS-Bryan-Yael
Bryan Laurrabaquio Ramírez 
Yael Gonzales
Equipo 8 
AJBooks — Gestor Personal de Libros
Aplicación iOS que permite explorar, buscar y guardar libros usando la API pública de Open Library. Los libros favoritos se guardan localmente en el dispositivo con SwiftData, sin necesidad de crear una cuenta, y siguen disponibles aunque no haya conexión a internet.
Tecnologías
	•	SwiftUI — interfaz
	•	SwiftData — persistencia local de "Mis libros"
	•	Open Library Search API (openlibrary.org/search.json) — búsqueda de libros
	•	Open Library Covers API (covers.openlibrary.org) — portadas
Flujos principales
1. Explorar desde Inicio
Al abrir la app, el usuario ve un catálogo destacado. Al tocar un libro entra al detalle, donde puede consultar su información y guardarlo.
Inicio → Detalle
<p float="left">
  <img src="docs/wireframes/01-inicio.png" width="260" alt="Pantalla de inicio con catálogo destacado" />
  <img src="docs/wireframes/04-detalle.jpeg" width="260" alt="Pantalla de detalle de un libro" />
</p>2. Buscar y Filtrar
El usuario va a la pestaña Buscar, escribe un título o autor y consulta los resultados que devuelve Open Library. Desde ahí puede abrir el detalle de cualquier resultado y guardarlo.
Buscar → Resultados → Detalle
<p float="left">
  <img src="docs/wireframes/02-buscar.jpeg" width="260" alt="Pantalla de búsqueda vacía" />
  <img src="docs/wireframes/03-resultados.jpeg" width="260" alt="Resultados de búsqueda para 'odisea'" />
  <img src="docs/wireframes/04-detalle.jpeg" width="260" alt="Detalle de un resultado de búsqueda" />
</p>3. Gestionar Guardados
El usuario va a la pestaña Mis libros para ver todo lo que ha guardado, y puede eliminar cualquier libro directamente desde ahí o desde su pantalla de detalle.
Mis libros → Detalle → Quitar de mis libros
<p float="left">
  <img src="docs/wireframes/05-mis-libros.jpeg" width="260" alt="Pantalla de libros guardados" />
</p>Estados de la interfaz
Además del flujo feliz, la app contempla:
	•	Cargando — skeletons mientras responde la API.
	•	Sin resultados — cuando una búsqueda no encuentra coincidencias.
	•	Error de conexión — con botón de reintentar.
	•	Mis libros vacío — cuando aún no se ha guardado ningún libro, con acceso directo a Buscar.
Datos del detalle
Cada libro muestra título, autor(es), año de publicación, descripción, idioma y número de ediciones cuando Open Library los provee. Si algún dato no está disponible (portada, año, descripción), se muestra un estado de reemplazo en vez de dejar el espacio vacío o romper el diseño.

### Road Map:

## Plan de implementación

Lo que se haría en la siguiente etapa, ordenado por tema visto en clase.

### Estado

- Crear el `BookStore` con `@Observable`, con la lista de libros y los favoritos
- Inyectarlo en la raíz de la app con `@Environment`
- Quitar `@State var saved` de `SecondView` y usar el dato del `BookStore`
- Mantener `searchText` como `@State` en `ContentView`

### Navegación

- Cambiar `NavigationView` por `NavigationStack`
- Usar `NavigationLink` y `navigationDestination` para ir al detalle
- Crear `FavoritesView` y agregar el acceso desde Inicio

### Componentes

- Mover `Book` a su propio archivo
- Extraer la fila del libro (`BookRow`) como subvista, porque el mismo diseño se repite

### Interfaz adaptativa y accesibilidad

- Revisar los tamaños fijos de las portadas (`frame` de 60×80 y 120×170) para que se adapten
- Probar con Dynamic Type
- Agregar labels descriptivos para VoiceOver (portada y botón Guardar)
- No depender solo del color: año y género van solo en rojo y en letra pequeña
- Mostrar un mensaje cuando la búsqueda no tenga resultados y cuando no haya favoritos
