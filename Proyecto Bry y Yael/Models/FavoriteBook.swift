
import Foundation
import SwiftData

@Model
class FavoriteBook {
    var bookID: String
    var title: String
    var author: String
    var year: String = ""
    var genre: String = ""

    init(
    bookID: String,
    title: String,
    author: String,
    year: String = "",
    genre: String = ""
    ) {
        self.bookID = bookID
        self.title = title
        self.author = author
        self.year = year
        self.genre = genre
    }
}

// El registro guarda texto vacío cuando el libro no tiene año o género.
// Así el esquema de SwiftData no cambia y los favoritos ya guardados siguen siendo válidos.
extension FavoriteBook {
    convenience init(book: Book) {
        self.init(
            bookID: book.id,
            title: book.title,
            author: book.author,
            year: book.year.map { String($0) } ?? "",
            genre: book.genre ?? ""
        )
    }

    // Reconstruye el libro desde los datos persistidos.
    func toBook() -> Book {
        Book(
            id: bookID,
            title: title,
            author: author,
            year: Int(year),
            genre: genre.isEmpty ? nil : genre,
            description: ""
        )
    }
}
