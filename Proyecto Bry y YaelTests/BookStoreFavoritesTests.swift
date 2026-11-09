import XCTest
@testable import Proyecto_Bry_y_Yael

// Servicio falso para las pruebas: guarda en una lista y cuenta las llamadas.
// Si storedFavorites es nil, simula que el servicio falló al leer.
@MainActor
final class MockFavoritesService: FavoritesServiceProtocol {

    var storedFavorites: [FavoriteBook]?
    var saveCalls = 0
    var removeCalls = 0

    init(storedFavorites: [FavoriteBook]? = []) {
        self.storedFavorites = storedFavorites
    }

    func fetchFavorites() -> [FavoriteBook]? {
        return storedFavorites
    }

    func saveFavorite(book: Book) {
        saveCalls += 1
        storedFavorites?.append(
            FavoriteBook(bookID: book.id, title: book.title, author: book.author)
        )
    }

    func removeFavorite(book: Book) {
        removeCalls += 1
        storedFavorites?.removeAll { favorite in
            favorite.bookID == book.id
        }
    }
}

// Pruebas de BookStore con el servicio falso: sin disco, sin API, repetibles.
@MainActor
final class BookStoreFavoritesTests: XCTestCase {

    // Caso normal: al crearse, el BookStore carga lo que ya estaba guardado.
    func testStoreLoadsSavedFavoritesFromService() {
        // Arrange
        let book = makeSeededStore().books[5]
        let saved = FavoriteBook(bookID: book.id, title: book.title, author: book.author)
        let mockService = MockFavoritesService(storedFavorites: [saved])

        // Act
        let store = makeSeededStore(favoritesService: mockService)

        // Assert
        XCTAssertTrue(store.isFavorite(store.books[5]))
        XCTAssertEqual(store.favorites.count, 1)
        XCTAssertEqual(store.favorites[0].title, "Frankenstein")
    }

    // Caso normal: marcar un favorito lo guarda a través del servicio.
    func testToggleFavoriteSavesThroughService() {
        // Arrange
        let mockService = MockFavoritesService()
        let store = makeSeededStore(favoritesService: mockService)

        // Act
        store.toggleFavorite(store.books[0])

        // Assert
        XCTAssertEqual(mockService.saveCalls, 1)
        XCTAssertTrue(store.isFavorite(store.books[0]))
        XCTAssertEqual(store.favoriteIDs.count, 1)
    }

    // Caso límite: marcar dos veces el mismo libro lo guarda y luego lo quita.
    func testToggleFavoriteTwiceRemovesIt() {
        // Arrange
        let mockService = MockFavoritesService()
        let store = makeSeededStore(favoritesService: mockService)

        // Act
        store.toggleFavorite(store.books[0])
        store.toggleFavorite(store.books[0])

        // Assert
        XCTAssertEqual(mockService.saveCalls, 1)
        XCTAssertEqual(mockService.removeCalls, 1)
        XCTAssertTrue(store.favorites.isEmpty)
    }

    // Caso sin resultados: si el servicio falla (nil), no hay favoritos.
    func testStoreHasNoFavoritesWhenServiceFails() {
        // Arrange
        let mockService = MockFavoritesService(storedFavorites: nil)

        // Act
        let store = makeSeededStore(favoritesService: mockService)

        // Assert
        XCTAssertTrue(store.favoriteIDs.isEmpty)
        XCTAssertTrue(store.favorites.isEmpty)
    }

    // El favorito se reconoce por el id de la fuente, no por el título.
    func testFavoriteIsRecognizedByIDNotByTitle() {
        // Arrange
        let mockService = MockFavoritesService()
        let store = makeSeededStore(favoritesService: mockService)
        let original = store.books[0]
        let otraEdicion = Book(id: "local-otra-edicion", title: original.title, author: original.author, year: "2000", genre: original.genre, description: "")
        store.catalogState = .content(store.books + [otraEdicion])

        // Act
        store.toggleFavorite(original)

        // Assert
        XCTAssertTrue(store.isFavorite(original))
        XCTAssertFalse(store.isFavorite(otraEdicion))
    }

    // La pantalla de Inicio muestra el contador que sale de lo persistido.
    func testListViewModelCountFollowsPersistedFavorites() {
        // Arrange
        let mockService = MockFavoritesService()
        let store = makeSeededStore(favoritesService: mockService)
        let viewModel = BookListViewModel(store: store)

        // Act
        store.toggleFavorite(store.books[2])

        // Assert
        XCTAssertEqual(viewModel.favoritesCount, 1)
    }
}
