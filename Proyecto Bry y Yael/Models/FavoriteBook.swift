import Foundation
import SwiftData

@Model
class FavoriteBook {
    var bookID: String
    var title: String
    var author: String
    var year: String = ""
    var genre: String = ""
    // Atributos agregados en la versión BYbooKS. Son opcionales para que SwiftData
    // haga una migración ligera automática: los favoritos guardados antes siguen
    // siendo válidos y simplemente quedan con nil (sin portada ni edición).
    var coverID: Int?
    var editionKey: String?

    init(
        bookID: String,
        title: String,
        author: String,
        year: String = "",
        genre: String = "",
        coverID: Int? = nil,
        editionKey: String? = nil
    ) {
        self.bookID = bookID
        self.title = title
        self.author = author
        self.year = year
        self.genre = genre
        self.coverID = coverID
        self.editionKey = editionKey
    }
}

// El registro guarda texto vacío cuando el libro no tiene año o género.
// Así el esquema original de SwiftData no cambia y los favoritos ya guardados siguen siendo válidos.
extension FavoriteBook {
    convenience init(book: Book) {
        self.init(
            bookID: book.id,
            title: book.title,
            author: book.author,
            year: book.year.map { String($0) } ?? "",
            genre: book.genre ?? "",
            coverID: book.coverID,
            editionKey: book.editionKey
        )
    }

    // Reconstruye el libro desde los datos persistidos.
    // La descripción no se guarda: se vuelve a consultar al abrir el detalle.
    func toBook() -> Book {
        Book(
            id: bookID,
            title: title,
            author: author,
            year: Int(year),
            genre: genre.isEmpty ? nil : genre,
            description: "",
            coverID: coverID,
            editionKey: editionKey
        )
    }
}
