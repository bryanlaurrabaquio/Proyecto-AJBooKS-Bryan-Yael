import Foundation
import Observation

// ViewModel de Detalle: trabaja con un solo libro y su estado de "guardado".
@Observable
class BookDetailViewModel {
    
    let book: Book

    init(book: Book) {
        self.book = book
        
    }


    func savedItem(in saved: [FavoriteBook]) -> FavoriteBook? {

            return saved.first { item in item.bookID == book.id}

        
    }


    func isSaved(in saved: [FavoriteBook]) -> Bool {

        return savedItem(in: saved) != nil

        
    }


    func buttonTitle(in saved: [FavoriteBook]) -> String {

        if isSaved(in: saved) {

            return "Quitar favoritos."
            
        }

        return "Guardar en favoritos."


        
    }


    func makeFavorite() -> FavoriteBook {

        return FavoriteBook(bookID: book.id, title: book.title, author:book.author)

        
    }


    
}
