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
    var year: String
    var genre: String
    var description: String
}

// Dato calculado del Model: el formato "año - género" se arma en un solo lugar,
// así todas las pantallas muestran el mismo texto.
extension Book {
    var subtitle: String {
        return year + " - " + genre
    }
}
