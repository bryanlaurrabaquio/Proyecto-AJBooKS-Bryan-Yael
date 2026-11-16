import Foundation

// Solo describe los datos de un libro.
// Hashable es necesario para navegar con NavigationLink(value:) y navigationDestination(for:).
struct Book: Identifiable, Hashable {
    // Identificador estable que entrega la fuente de datos (no se calcula aquí).
    // Con la API es el campo `key` de la obra en Open Library (con la forma "/works/OL...W").
    // Los datos de ejemplo y de pruebas usan ids locales.
    let id: String
    var title: String
    var author: String
    // La API no siempre entrega año ni género, por eso son opcionales (nil = dato no disponible).
    var year: Int?
    var genre: String?
    // Descripción en español que ya se conoce al crear el libro (por ejemplo, en vistas previas).
    // La búsqueda de Open Library no la incluye: se consulta aparte y se guarda en BookStore.
    var description: String = ""
    // Identificador de la portada en Open Library (campo `cover_i`). nil = sin portada.
    var coverID: Int? = nil
    // Edición que se muestra (de preferencia en español), con la forma "/books/OL...M".
    // Sirve para pedir la descripción de esa edición concreta.
    var editionKey: String? = nil
}

// Dato calculado del Model: el formato "año - género" se arma en un solo lugar,
// así todas las pantallas muestran el mismo texto.
// Solo une los datos que existen; si no hay ninguno devuelve nil.
extension Book {
    var subtitle: String? {
        let parts = [year.map { String($0) }, genre].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " - ")
    }

    // URL de la portada en el tamaño pedido. El formato de la URL lo conoce el servicio.
    func coverURL(size: CoverSize) -> URL? {
        OpenLibraryCovers.url(coverID: coverID, size: size)
    }
}
