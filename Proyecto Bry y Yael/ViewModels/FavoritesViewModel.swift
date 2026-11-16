import Foundation
import Observation

// ViewModel de Favoritos: expone la lista de favoritos, si está vacía y sus descripciones.
@MainActor
@Observable
final class FavoritesViewModel {
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

    func isFavorite(_ book: Book) -> Bool {
        store.isFavorite(book)
    }

    func removeFavorite(_ book: Book) {
        if store.isFavorite(book) {
            store.toggleFavorite(book)
        }
    }

    func descriptionPreview(for book: Book) -> DescriptionPreview {
        store.descriptionState(for: book).preview
    }

    func prefetchDescription(for book: Book) {
        store.requestDescription(for: book)
    }
}
