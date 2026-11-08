
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
