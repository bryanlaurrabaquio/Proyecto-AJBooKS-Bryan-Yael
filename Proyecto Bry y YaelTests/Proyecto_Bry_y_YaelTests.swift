import XCTest
@testable import Proyecto_Bry_y_Yael

// Pruebas unitarias con XCTest. Usan solo datos locales, sin API ni red,
// así que se ejecutan igual cada vez.
@MainActor
final class Proyecto_Bry_y_YaelTests: XCTestCase {

    // MARK: - Búsqueda (BookListViewModel)

    // Caso normal: una búsqueda con coincidencia devuelve ese libro.
    func testBusquedaNormalEncuentraElLibro() {
        let viewModel = BookListViewModel(store: BookStore())
        viewModel.searchText = "principito"

        XCTAssertEqual(viewModel.filteredBooks.count, 1)
        XCTAssertEqual(viewModel.filteredBooks[0].title, "El principito")
        XCTAssertFalse(viewModel.noResults)
    }

    // Caso límite: búsqueda vacía devuelve todo el catálogo.
    func testBusquedaVaciaDevuelveTodosLosLibros() {
        let store = BookStore()
        let viewModel = BookListViewModel(store: store)

        XCTAssertEqual(viewModel.filteredBooks.count, store.books.count)
        XCTAssertFalse(viewModel.noResults)
    }

    // Caso sin resultados: un texto inexistente devuelve lista vacía.
    func testBusquedaSinCoincidenciasNoDevuelveLibros() {
        let viewModel = BookListViewModel(store: BookStore())
        viewModel.searchText = "zzzz"

        XCTAssertTrue(viewModel.filteredBooks.isEmpty)
        XCTAssertTrue(viewModel.noResults)
    }

    // La búsqueda no distingue mayúsculas de minúsculas.
    func testBusquedaIgnoraMayusculas() {
        let viewModel = BookListViewModel(store: BookStore())
        viewModel.searchText = "ODISEA"

        XCTAssertEqual(viewModel.filteredBooks.count, 1)
        XCTAssertEqual(viewModel.filteredBooks[0].title, "La Odisea")
    }

    // MARK: - Identificador estable (Book)

    // El mismo libro siempre produce el mismo id (base para no duplicar).
    func testElIdDelLibroEsEstable() {
        let libroA = Book(title: "Frankenstein", author: "Mary Shelley", year: "1818", genre: "Terror", description: "")
        let libroB = Book(title: "Frankenstein", author: "Mary Shelley", year: "1818", genre: "Terror", description: "")

        XCTAssertEqual(libroA.id, libroB.id)
    }

    // MARK: - Colección guardada (BookDetailViewModel)

    // Sin nada guardado, el libro se reconoce como no guardado.
    func testLibroNoGuardadoCuandoLaColeccionEstaVacia() {
        let book = BookStore().books[0]
        let viewModel = BookDetailViewModel(book: book)
        let saved: [FavoriteBook] = []

        XCTAssertFalse(viewModel.isSaved(in: saved))
        XCTAssertNil(viewModel.savedItem(in: saved))
        XCTAssertEqual(viewModel.buttonTitle(in: saved), "Guardar")
    }

    // Si ya está guardado se reconoce por su id (por eso no se vuelve a insertar).
    func testLibroGuardadoSeReconocePorSuId() {
        let book = BookStore().books[0]
        let viewModel = BookDetailViewModel(book: book)
        let saved = [viewModel.makeFavorite()]

        XCTAssertTrue(viewModel.isSaved(in: saved))
        XCTAssertNotNil(viewModel.savedItem(in: saved))
        XCTAssertEqual(viewModel.buttonTitle(in: saved), "Guardado")
        XCTAssertEqual(viewModel.buttonAccessibilityLabel(in: saved), "Quitar de favoritos")
    }

    // Un libro guardado distinto no cuenta como este libro.
    func testOtroLibroGuardadoNoAfectaAEsteLibro() {
        let store = BookStore()
        let otro = BookDetailViewModel(book: store.books[1]).makeFavorite()
        let viewModel = BookDetailViewModel(book: store.books[0])

        XCTAssertFalse(viewModel.isSaved(in: [otro]))
    }

    // MARK: - Lista de favoritos (FavoritesViewModel)

    // Sin guardados, la lista de favoritos queda vacía.
    func testFavoritosVaciosSinLibrosGuardados() {
        let viewModel = FavoritesViewModel(store: BookStore())

        XCTAssertTrue(viewModel.favoriteBooks(from: []).isEmpty)
    }

    // Con guardados, devuelve solo los libros del catálogo que coinciden.
    func testFavoritosDevuelveSoloLosLibrosGuardados() {
        let store = BookStore()
        let viewModel = FavoritesViewModel(store: store)
        let saved = [BookDetailViewModel(book: store.books[2]).makeFavorite()]

        let result = viewModel.favoriteBooks(from: saved)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].title, store.books[2].title)
    }
}
