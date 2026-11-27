import Foundation

// Un libro que el local tiene en su inventario, con su existencia física.
// Se identifica con el mismo id que Book (la clave de Open Library), así que la búsqueda
// puede mostrar el stock del libro correcto.
// Guarda título, autor y portada para poder mostrar el inventario sin consultar la red.
nonisolated struct InventoryItem: Identifiable, Hashable {
    let bookID: String
    var title: String
    var author: String
    var coverID: Int?
    // Existencia física: ejemplares que hay en el local (incluye los apartados que aún no se entregan).
    var existence: Int

    var id: String { bookID }
}

extension InventoryItem {
    // El libro tal como lo usa el resto de la app (portada, navegación).
    @MainActor
    var asBook: Book {
        Book(id: bookID, title: title, author: author, description: "", coverID: coverID)
    }
}
