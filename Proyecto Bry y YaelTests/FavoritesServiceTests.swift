import XCTest
import SwiftData
@testable import Proyecto_Bry_y_Yael

// Pruebas del servicio REAL de SwiftData, pero con una base EN MEMORIA:
// no tocan el disco ni dependen de una API, así que se repiten igual cada vez.
@MainActor
final class FavoritesServiceTests: XCTestCase {

    // El contenedor se guarda en una propiedad para que siga vivo durante toda la prueba.
    private var container: ModelContainer?

    private let frankenstein = Book(id: "local-frankenstein", title: "Frankenstein", author: "Mary Shelley", year: "1818", genre: "Terror", description: "")
    private let pedroParamo = Book(id: "local-pedro-paramo", title: "Pedro Páramo", author: "Juan Rulfo", year: "1955", genre: "Realismo mágico", description: "")

    // Crea un contexto nuevo sobre una base de datos temporal (isStoredInMemoryOnly: true).
    private func makeContext() throws -> ModelContext {
        let schema = Schema([
            FavoriteBook.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let newContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        container = newContainer
        return ModelContext(newContainer)
    }

    // Caso sin resultados: sin guardar nada, la lista está vacía.
    func testFetchFavoritesIsEmptyWhenNothingWasSaved() throws {
        // Arrange
        let service = FavoritesService(context: try makeContext())

        // Act
        let result = service.fetchFavorites()

        // Assert
        XCTAssertEqual(result?.count, 0)
    }

    // Caso normal: guardar un libro lo deja en la colección.
    func testSaveFavoriteStoresTheBook() throws {
        // Arrange
        let service = FavoritesService(context: try makeContext())

        // Act
        service.saveFavorite(book: frankenstein)

        // Assert
        let saved = service.fetchFavorites() ?? []
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved[0].bookID, frankenstein.id)
        XCTAssertEqual(saved[0].title, "Frankenstein")
    }

    // Caso límite: guardar dos veces el mismo libro no lo duplica.
    func testSaveSameFavoriteTwiceDoesNotDuplicateIt() throws {
        // Arrange
        let service = FavoritesService(context: try makeContext())

        // Act
        service.saveFavorite(book: frankenstein)
        service.saveFavorite(book: frankenstein)

        // Assert
        let saved = service.fetchFavorites() ?? []
        XCTAssertEqual(saved.count, 1)
    }

    // Eliminar quita solo el libro indicado.
    func testRemoveFavoriteDeletesOnlyThatBook() throws {
        // Arrange
        let service = FavoritesService(context: try makeContext())
        service.saveFavorite(book: frankenstein)
        service.saveFavorite(book: pedroParamo)

        // Act
        service.removeFavorite(book: frankenstein)

        // Assert
        let saved = service.fetchFavorites() ?? []
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved[0].bookID, pedroParamo.id)
    }

    // Entrada inválida: quitar un libro que nunca se guardó no cambia nada.
    func testRemoveFavoriteThatWasNeverSavedChangesNothing() throws {
        // Arrange
        let service = FavoritesService(context: try makeContext())
        service.saveFavorite(book: frankenstein)

        // Act
        service.removeFavorite(book: pedroParamo)

        // Assert
        let saved = service.fetchFavorites() ?? []
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved[0].bookID, frankenstein.id)
    }

    // Persistencia: un servicio nuevo con otro contexto (como al reabrir la app)
    // sigue viendo lo que se guardó.
    func testFavoritesSurviveWithANewContext() throws {
        // Arrange
        let firstService = FavoritesService(context: try makeContext())
        firstService.saveFavorite(book: pedroParamo)

        // Act: otro contexto sobre el mismo contenedor
        let sameContainer = try XCTUnwrap(container)
        let secondService = FavoritesService(context: ModelContext(sameContainer))

        // Assert
        let saved = secondService.fetchFavorites() ?? []
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved[0].bookID, pedroParamo.id)
    }

    // El favorito se reconoce por el id de la fuente, no por el título:
    // dos libros con el mismo título pero distinto id son favoritos distintos.
    func testBooksWithSameTitleButDifferentIDAreDifferentFavorites() throws {
        // Arrange
        let service = FavoritesService(context: try makeContext())
        let otraEdicion = Book(id: "local-frankenstein-otra-edicion", title: "Frankenstein", author: "Mary Shelley", year: "1831", genre: "Terror", description: "")

        // Act
        service.saveFavorite(book: frankenstein)
        service.saveFavorite(book: otraEdicion)

        // Assert
        let saved = service.fetchFavorites() ?? []
        XCTAssertEqual(saved.count, 2)
    }
}
