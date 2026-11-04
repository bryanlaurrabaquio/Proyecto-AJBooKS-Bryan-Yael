
import Foundation
import SwiftData


@Model
class FavoriteBook {
    var bookID: String
    var title: String
    var author: String

    init(bookID: String, title: String, author: String) {
        self.bookID = bookID
        self.title = title
        self.author = author
    }
}
