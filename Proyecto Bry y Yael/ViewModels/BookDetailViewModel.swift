import Foundation
import Observation

// ViewModel de Detalle: trabaja con un solo libro y su estado de "guardado".
@MainActor
@Observable
final class BookDetailViewModel {
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

    var descriptionText: String {
        if book.description.isEmpty {
            return "Descripción no disponible."
        }

        return book.description
    }

    // Textos para mostrar cuando la API no entregó el dato.
    var yearText: String {
        book.year.map { String($0) } ?? "Desconocido"
    }

    var genreText: String {
        book.genre ?? "Sin género"
    }

    func toggleSaved() {
        store.toggleFavorite(book)
    }

}
