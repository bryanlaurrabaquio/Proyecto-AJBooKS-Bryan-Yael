import Foundation
import Observation


@Observable
class BookDetailViewModel {
    let book: Book

    init(book: Book) {
        self.book = book
    }

    
    func savedItem(in saved: [FavoriteBook]) -> FavoriteBook? {
        return saved.first { item in
            item.bookID == book.id
        }
    }

    func isSaved(in saved: [FavoriteBook]) -> Bool {
        return savedItem(in: saved) != nil
    }

    func buttonTitle(in saved: [FavoriteBook]) -> String {
        if isSaved(in: saved) {
            return "Guardado"
        }
        return "Guardar"
    }

    func buttonAccessibilityLabel(in saved: [FavoriteBook]) -> String {
        if isSaved(in: saved) {
            return "Quitar de favoritos"
        }
        return "Guardar en favoritos"
    }

    
    func makeFavorite() -> FavoriteBook {
        return FavoriteBook(bookID: book.id, title: book.title, author: book.author)
    }
}
