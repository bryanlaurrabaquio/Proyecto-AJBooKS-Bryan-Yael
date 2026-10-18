import Foundation

// Modelo de un libro.
// - Identifiable: ForEach puede distinguir cada libro por su `id`.
// - Hashable: NavigationLink(value:) necesita valores Hashable para navegar.
// El `id` es fijo (no se genera con UUID()), así el mismo libro conserva
// siempre su identidad y se puede guardar en la lista de favoritos.
struct Book: Identifiable, Hashable {
    let id: Int
    let title: String
    let author: String
    let year: String
    let genre: String
    let description: String

    // Regla propia del libro: coincide con una búsqueda si su título
    // contiene el texto, sin importar mayúsculas o minúsculas.
    func matches(_ searchText: String) -> Bool {
        title.localizedCaseInsensitiveContains(searchText)
    }
}