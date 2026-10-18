import Foundation
import Observation

// ViewModel de Inicio: prepara la lista de libros para ContentView.
// No importa SwiftUI: solo contiene lógica de presentación.
@Observable
class BookListViewModel {
    // Fuente única de verdad compartida (no se copia).
    private let store: BookStore

    // Estado local de la pantalla: el texto de búsqueda.
    var searchText = ""

    init(store: BookStore) {
        self.store = store
    }

    // Libros que coinciden con la búsqueda (early return).
    var filteredBooks: [Book] {
        if searchText == "" {
            return store.books
        }
        return store.books.filter { book in
            book.title.lowercased().contains(searchText.lowercased())
        }
    }

    // La vista solo muestra u oculta el mensaje, no repite la cuenta.
    var noResults: Bool {
        return filteredBooks.isEmpty
    }

    // Número que se muestra en el botón de Favoritos.
    var favoritesCount: Int {
        return store.favorites.count
    }
}
