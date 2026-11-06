import SwiftUI

// Single Source of Truth: aquí viven la lista de libros y los favoritos.
// Las vistas no guardan copias; leen y modifican este objeto compartido.
// Los favoritos se guardan en disco a través de un servicio (SwiftData),
// y BookStore los vuelve a leer después de cada cambio.
@MainActor
@Observable
final class BookStore {
    // Los ids son provisionales (catálogo escrito a mano).
    // Al integrar Open Library, cada libro usará su `key` como id.
    var books: [Book] = [
        Book(id: "local-odisea", title: "La Odisea", author: "Homero", year: "Desconocido", genre: "Aventura", description: "Tras la guerra de Troya, Odiseo emprende un largo viaje de regreso a su hogar en Ítaca."),
        Book(id: "local-el-principito", title: "El principito", author: "Antoine de Saint-Exupéry", year: "1943", genre: "Fantasía", description: "Un piloto perdido en el desierto conoce a un pequeño príncipe que viene de otro planeta."),
        Book(id: "local-cien-anos-de-soledad", title: "Cien años de soledad", author: "Gabriel García Márquez", year: "1967", genre: "Realismo mágico", description: "La historia de varias generaciones de la familia Buendía en el pueblo de Macondo."),
        Book(id: "local-pedro-paramo", title: "Pedro Páramo", author: "Juan Rulfo", year: "1955", genre: "Realismo mágico", description: "Juan Preciado llega a Comala buscando a su padre y encuentra un pueblo lleno de murmullos."),
        Book(id: "local-don-quijote", title: "Don Quijote de la Mancha", author: "Miguel de Cervantes", year: "1605", genre: "Clásico", description: "Un hidalgo sale a buscar aventuras como caballero andante junto a Sancho Panza."),
        Book(id: "local-frankenstein", title: "Frankenstein", author: "Mary Shelley", year: "1818", genre: "Terror", description: "Un científico da vida a una criatura y tiene que enfrentar las consecuencias.")
    ]

    // Guardamos solo los ids de los favoritos para no duplicar los libros.
    private(set) var favoriteIDs: [String] = []

    // El servicio que guarda y lee la colección personal.
    private let favoritesService: any FavoritesServiceProtocol

    // Por defecto usa el servicio en memoria (previews y pruebas).
    // La App le pasa el servicio real de SwiftData.
    init(favoritesService: any FavoritesServiceProtocol = InMemoryFavoritesService()) {
        self.favoritesService = favoritesService

        loadFavorites()
    }

    // Los favoritos se calculan a partir de la lista única de libros.
    var favorites: [Book] {
        books.filter { book in
            favoriteIDs.contains(book.id)
        }
    }

    func isFavorite(_ book: Book) -> Bool {
        return favoriteIDs.contains(book.id)
    }

    // Agrega o quita el libro en el servicio y vuelve a leer lo guardado,
    // para que la interfaz siempre muestre lo que realmente está persistido.
    func toggleFavorite(_ book: Book) {
        if isFavorite(book) {
            favoritesService.removeFavorite(book: book)
        } else {
            favoritesService.saveFavorite(book: book)
        }

        loadFavorites()
    }

    // Lee los favoritos guardados. Si el servicio falla (nil), queda una lista vacía.
    func loadFavorites() {
        let saved = favoritesService.fetchFavorites() ?? []
        favoriteIDs = saved.map { favorite in
            favorite.bookID
        }
    }
}
