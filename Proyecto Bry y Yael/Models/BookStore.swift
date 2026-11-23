import Foundation
import Observation

// Fuente única de verdad: el catálogo remoto (según el estado de la consulta a la API)
// y los favoritos guardados en SwiftData.
@MainActor
@Observable
final class BookStore {

    // Fuente única de verdad del catálogo remoto.
    var catalogState: LoadState = .idle

    // Los libros se obtienen del estado de la API.
    var books: [Book] {
        if case .content(let items) = catalogState {
            return items
        }
        return []
    }

    // Favoritos guardados en SwiftData.
    private(set) var favoriteRecords: [FavoriteBook] = []

    // Ids de los favoritos. Set no admite repetidos y buscar un id es directo.
    // Se actualiza en loadFavorites(), cada vez que cambian los registros.
    private(set) var favoriteIDs: Set<String> = []

    // Se reconstruyen desde los datos persistidos.
    // No dependen de los resultados de Open Library.
    var favorites: [Book] {
        favoriteRecords.map { $0.toBook() }
    }

    private let favoritesService: any FavoritesServiceProtocol

    // Si no se indica un servicio se usan favoritos en memoria (vistas previas y pruebas).
    // Se crea dentro del init (en el MainActor) para evitar la advertencia
    // "Call to main actor-isolated initializer in a synchronous nonisolated context".
    init(
    favoritesService: (any FavoritesServiceProtocol)? = nil
    ) {
        self.favoritesService = favoritesService ?? InMemoryFavoritesService()
        loadFavorites()
    }

    func isFavorite(_ book: Book) -> Bool {
        favoriteIDs.contains(book.id)
    }

    func toggleFavorite(_ book: Book) {
        if isFavorite(book) {
            favoritesService.removeFavorite(book: book)
        } else {
            favoritesService.saveFavorite(book: book)
        }

        loadFavorites()
    }

    func loadFavorites() {
        favoriteRecords =
        favoritesService.fetchFavorites() ?? []

        favoriteIDs = Set(favoriteRecords.map { $0.bookID })
    }
}
