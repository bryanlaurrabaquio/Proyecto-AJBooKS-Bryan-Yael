import Foundation
import SwiftData

// Contrato del servicio de favoritos.
protocol FavoritesServiceProtocol {
    func fetchFavorites() -> [FavoriteBook]?
    func saveFavorite(book: Book)
    func removeFavorite(book: Book)
}

// Guarda en disco con SwiftData usando un ModelContext.
class FavoritesService: FavoritesServiceProtocol {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // Lee todos los favoritos guardados.
    func fetchFavorites() -> [FavoriteBook]? {
        do {
            return try context.fetch(FetchDescriptor<FavoriteBook>())
        } catch {
            print("Hubo un error al leer los favoritos: \(error)")
            return nil
        }
    }

    // Busca un favorito por el id del libro.
    func searchFavorite(bookID: String) -> [FavoriteBook]? {
        let description = FetchDescriptor<FavoriteBook>(
            predicate: #Predicate { favorite in
                favorite.bookID == bookID
            }
        )

        do {
            return try context.fetch(description)
        } catch {
            print("Hubo un error al buscar el favorito \(bookID): \(error)")
            return nil
        }
    }

    // Agrega un libro a la colección. Si ya existe, no lo vuelve a guardar (sin duplicados).
    func saveFavorite(book: Book) {
        let existing = searchFavorite(bookID: book.id) ?? []
        if !existing.isEmpty {
            return
        }

        context.insert(
            FavoriteBook(bookID: book.id, title: book.title, author: book.author)
        )

        save()
    }

    //Eliminacion de libros.
    func removeFavorite(book: Book) {
        let existing = searchFavorite(bookID: book.id) ?? []
        for favorite in existing {
            context.delete(favorite)
        }

        save()
    }

    private func save() {
        do {
            try context.save()
        } catch {
            print("Hubo un error al guardar: \(error)")
        }
    }
}


class InMemoryFavoritesService: FavoritesServiceProtocol {

    private var saved: [FavoriteBook] = []

    func fetchFavorites() -> [FavoriteBook]? {
        return saved
    }

    func saveFavorite(book: Book) {
        let alreadySaved = saved.contains { favorite in
            favorite.bookID == book.id
        }
        if alreadySaved {
            return
        }
        saved.append(
            FavoriteBook(bookID: book.id, title: book.title, author: book.author)
        )
    }

    func removeFavorite(book: Book) {
        saved.removeAll { favorite in
            favorite.bookID == book.id
        }
    }
}
