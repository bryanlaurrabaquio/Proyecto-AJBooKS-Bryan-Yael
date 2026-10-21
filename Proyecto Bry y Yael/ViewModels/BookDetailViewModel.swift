import Foundation
import Observation

// ViewModel de Detalle: trabaja con un solo libro y su estado de "guardado".
@Observable
class BookDetailViewModel {
    private let store: BookStore
    let book: Book

    init(book: Book, store: BookStore) {
        self.book = book
        self.store = store
    }

    // Se lee del BookStore, no se guarda una copia aquí.
    var isSaved: Bool {
        return store.isFavorite(book)
    }

    var buttonTitle: String {
        if isSaved {
            return "Guardado"
        }
        return "Guardar"
    }

    // Texto que lee VoiceOver en el botón.
    var buttonAccessibilityLabel: String {
        if isSaved {
            return "Quitar de favoritos"
        }
        return "Guardar en favoritos"
    }

    func toggleSaved() {
        store.toggleFavorite(book)
    }
}
