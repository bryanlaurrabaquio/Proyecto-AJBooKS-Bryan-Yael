
import Foundation
import SwiftData

// Contrato del servicio de favoritos.
protocol FavoritesServiceProtocol {
    func fetchFavorites() -> [FavoriteBook]?
    func saveFavorite(book: Book)
    func removeFavorite(book: Book)
}

// Guarda en disco con SwiftData utilizando ModelContext.
class FavoritesService: FavoritesServiceProtocol {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // Obtiene los favoritos guardados.
    func fetchFavorites() -> [FavoriteBook]? {
        do {
            return try context.fetch(
                FetchDescriptor<FavoriteBook>()
            )
        } catch {
            print("Error al leer favoritos: \(error)")
            return nil
        }
    }

    // Busca un favorito por su identificador.
    func searchFavorite(bookID: String) -> [FavoriteBook]? {
        let descriptor = FetchDescriptor<FavoriteBook>(
            predicate: #Predicate { favorite in
                favorite.bookID == bookID
            }
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("Error al buscar favorito \(bookID): \(error)")
            return nil
        }
    }

    // Guarda un libro sin crear duplicados.
    func saveFavorite(book: Book) {
        let existing = searchFavorite(bookID: book.id) ?? []

        if !existing.isEmpty {
            return
        }

        let favorite = FavoriteBook(
            bookID: book.id,
            title: book.title,
            author: book.author,
            year: book.year,
            genre: book.genre
        )

        context.insert(favorite)

        save()
    }

    // Elimina un libro de favoritos.
    func removeFavorite(book: Book) {
        let existing = searchFavorite(bookID: book.id) ?? []

        for favorite in existing {
            context.delete(favorite)
        }

        save()
    }

    // Guarda los cambios en SwiftData.
    private func save() {
        do {
            try context.save()
        } catch {
            print("Error al guardar favoritos: \(error)")
        }
    }
}

// Servicio de favoritos en memoria.
// Se utiliza en Previews y pruebas unitarias.
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

        let favorite = FavoriteBook(
            bookID: book.id,
            title: book.title,
            author: book.author,
            year: book.year,
            genre: book.genre
        )

        saved.append(favorite)
    }

    func removeFavorite(book: Book) {
        saved.removeAll { favorite in
            favorite.bookID == book.id
        }
    }
}
