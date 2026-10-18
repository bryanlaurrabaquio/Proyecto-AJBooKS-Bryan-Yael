import Foundation
import Observation

// ViewModel de la pantalla de Inicio (ContentView).
// Se encarga del texto de búsqueda y de decidir qué libros se muestran.
// No guarda copia de los libros ni de los favoritos: los recibe del BookStore,
// que sigue siendo la única fuente de verdad.
@Observable
class BookListViewModel {
    // Lo que el usuario escribe en el campo de búsqueda.
    var searchText = ""

    // Texto de búsqueda sin espacios al inicio ni al final,
    // para que "odisea " también encuentre "La Odisea".
    var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespaces)
    }

    // Libros que coinciden con la búsqueda (todos si el campo está vacío).
    func filteredBooks(from books: [Book]) -> [Book] {
        if trimmedSearchText.isEmpty {
            return books
        }
        return books.filter { book in
            book.matches(trimmedSearchText)
        }
    }
}