import Foundation
import Observation


@Observable
class FavoritesViewModel {
    private let store: BookStore

    init(store: BookStore) {
        self.store = store
    }

    func favoriteBooks(from saved: [FavoriteBook]) -> [Book] {
        return store.books.filter { book in
            saved.contains { item in
                item.bookID == book.id
            }
        }
    }
}
