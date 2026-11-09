#if DEBUG
import Foundation

// Datos de ejemplo solo para vistas previas: no dependen de la red y son fáciles de cambiar.
extension Book {
    static let samples: [Book] = [
        // Sin año: sirve para ver cómo se comporta la interfaz con datos opcionales.
        Book(
            id: "sample-odisea",
            title: "La Odisea",
            author: "Homero",
            year: nil,
            genre: "Aventura",
            description: "Libro utilizado en la vista previa."
        ),
        Book(
            id: "sample-principito",
            title: "El principito",
            author: "Antoine de Saint-Exupéry",
            year: 1943,
            genre: "Fantasía",
            description: ""
        ),
        Book(
            id: "sample-quijote",
            title: "Don Quijote de la Mancha",
            author: "Miguel de Cervantes",
            year: 1605,
            genre: "Clásico",
            description: ""
        ),
        // Sin año ni género.
        Book(
            id: "sample-sin-datos",
            title: "Libro sin datos",
            author: "Autor desconocido",
            year: nil,
            genre: nil,
            description: ""
        )
    ]
}

// Servicio falso: entrega los libros de ejemplo sin consultar Open Library.
struct PreviewBookService: BookServicing {
    var books: [Book] = Book.samples

    func fetchBooks(query: String) async throws -> [Book] {
        books
    }
}

extension BookStore {
    // Store con favoritos en memoria para vistas previas (no escribe en disco).
    static func preview(favorites: [Book] = []) -> BookStore {
        let store = BookStore()
        for book in favorites {
            store.toggleFavorite(book)
        }
        return store
    }
}
#endif
