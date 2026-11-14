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

    var favoriteIDs: [String] {
        favoriteRecords.map { $0.bookID }
    }

    // Se reconstruyen desde los datos persistidos.
    // No dependen de los resultados de Open Library.
    var favorites: [Book] {
        favoriteRecords.map { $0.toBook() }
    }

    private let favoritesService: any FavoritesServiceProtocol

    init(
    favoritesService: any FavoritesServiceProtocol =
    InMemoryFavoritesService()
    ) {
        self.favoritesService = favoritesService
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
    }
}
