import Foundation

// Solo describe los datos de un libro.
// Hashable es necesario para navegar con NavigationLink(value:) y navigationDestination(for:).
struct Book: Identifiable, Hashable {
    let id = UUID()
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
