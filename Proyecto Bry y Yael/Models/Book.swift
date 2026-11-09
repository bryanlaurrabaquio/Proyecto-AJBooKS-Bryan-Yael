import Foundation

// Solo describe los datos de un libro.
// Hashable es necesario para navegar con NavigationLink(value:) y navigationDestination(for:).
struct Book: Identifiable, Hashable {
    // Identificador estable que entrega la fuente de datos (no se calcula aquí).
    // Con la API será el campo `key` de Open Library (con la forma "/works/OL...W").
    // BookStore usa ids locales provisionales.
    let id: String
    var title: String
    var author: String
    // La API no siempre entrega año ni género, por eso son opcionales (nil = dato no disponible).
    var year: Int?
    var genre: String?
    var description: String
}

// Dato calculado del Model: el formato "año - género" se arma en un solo lugar,
// así todas las pantallas muestran el mismo texto.
// Solo une los datos que existen; si no hay ninguno devuelve nil.
extension Book {
    var subtitle: String? {
        let parts = [year.map { String($0) }, genre].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " - ")
    }
}
