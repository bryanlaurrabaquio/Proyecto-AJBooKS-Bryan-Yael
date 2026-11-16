#if DEBUG
import Foundation

// Datos de ejemplo solo para vistas previas: no dependen de la red y son fáciles de cambiar.
// Las descripciones dicen explícitamente que son de ejemplo: no son sinopsis reales.
extension Book {
    static let samples: [Book] = [
        // Sin año: sirve para ver cómo se comporta la interfaz con datos opcionales.
        // La portada es real: edición de 1921 de la Universidad Nacional de México en Open Library.
        Book(
            id: "sample-odisea",
            title: "La Odisea",
            author: "Homero",
            year: nil,
            genre: "Poesía épica",
            description: "Texto de ejemplo para la vista previa. En la app, la descripción se consulta en Open Library y solo se muestra aquí cuando está en español.",
            coverID: 5784739
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
            genre: "Clásicos",
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

// Servicio falso de descripciones: muestra los distintos estados sin usar la red.
struct PreviewDescriptionService: BookDescriptionServicing {
    func fetchDescription(for book: Book) async throws -> BookDescription {
        switch book.id {
        case "sample-principito":
            return .otherLanguage(
                text: "Sample text used only in previews to show the translation option.",
                languageCode: "en"
            )
        case "sample-sin-datos":
            throw BookServiceError.connectivity
        default:
            return .unavailable
        }
    }
}

extension BookStore {
    // Store con favoritos en memoria para vistas previas (no escribe en disco ni usa la red).
    static func preview(favorites: [Book] = []) -> BookStore {
        let store = BookStore(descriptionService: PreviewDescriptionService())
        for book in favorites {
            store.toggleFavorite(book)
        }
        return store
    }
}
#endif
