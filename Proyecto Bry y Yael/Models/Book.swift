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
