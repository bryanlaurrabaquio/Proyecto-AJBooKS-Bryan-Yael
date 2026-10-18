import Foundation
import Observation

// ViewModel de Favoritos: expone la lista de favoritos y si está vacía.
@Observable
class FavoritesViewModel {
    private let store: BookStore

    init(store: BookStore) {
        self.store = store
    }

    var favorites: [Book] {
        return store.favorites
    }

    var isEmpty: Bool {
        return favorites.isEmpty
    }

    func removeFavorite(_ book: Book) {
        if store.isFavorite(book) {
            store.toggleFavorite(book)
        }
    }
}
