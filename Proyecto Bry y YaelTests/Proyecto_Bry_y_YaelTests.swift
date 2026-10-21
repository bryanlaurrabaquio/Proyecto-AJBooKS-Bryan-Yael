import Testing
@testable import Proyecto_Bry_y_Yael

// Pruebas de la lógica que salió de las vistas: se prueban sin abrir la interfaz.
@MainActor
struct Proyecto_Bry_y_YaelTests {

    // MARK: - Book

    @Test func subtitleUneAnioYGenero() {
        let book = Book(title: "Frankenstein", author: "Mary Shelley", year: "1818", genre: "Terror", description: "")
        #expect(book.subtitle == "1818 - Terror")
    }

    // MARK: - BookListViewModel

    @Test func sinBusquedaMuestraTodosLosLibros() {
        let store = BookStore()
        let viewModel = BookListViewModel(store: store)

        #expect(viewModel.filteredBooks.count == store.books.count)
        #expect(viewModel.noResults == false)
    }

    @Test func busquedaFiltraPorTituloSinImportarMayusculas() {
        let viewModel = BookListViewModel(store: BookStore())
        viewModel.searchText = "ODISEA"

        #expect(viewModel.filteredBooks.count == 1)
        #expect(viewModel.filteredBooks[0].title == "La Odisea")
    }

    @Test func busquedaSinCoincidenciasActivaNoResults() {
        let viewModel = BookListViewModel(store: BookStore())
        viewModel.searchText = "zzzz"

        #expect(viewModel.filteredBooks.isEmpty)
        #expect(viewModel.noResults == true)
    }

    @Test func favoritesCountSigueAlStore() {
        let store = BookStore()
        let viewModel = BookListViewModel(store: store)
        #expect(viewModel.favoritesCount == 0)

        store.toggleFavorite(store.books[0])
        #expect(viewModel.favoritesCount == 1)
    }

    // MARK: - BookDetailViewModel

    @Test func detalleAlternaGuardadoYTextoDelBoton() {
        let store = BookStore()
        let viewModel = BookDetailViewModel(book: store.books[0], store: store)

        #expect(viewModel.isSaved == false)
        #expect(viewModel.buttonTitle == "Guardar")
        #expect(viewModel.buttonAccessibilityLabel == "Guardar en favoritos")

        viewModel.toggleSaved()

        #expect(viewModel.isSaved == true)
        #expect(viewModel.buttonTitle == "Guardado")
        #expect(viewModel.buttonAccessibilityLabel == "Quitar de favoritos")
        #expect(store.isFavorite(store.books[0]))
    }

    // MARK: - FavoritesViewModel

    @Test func favoritosEmpiezaVacioYSeActualizaConElStore() {
        let store = BookStore()
        let viewModel = FavoritesViewModel(store: store)
        #expect(viewModel.isEmpty == true)

        store.toggleFavorite(store.books[1])

        #expect(viewModel.isEmpty == false)
        #expect(viewModel.favorites.count == 1)
    }

    @Test func quitarFavoritoLoSacaDeLaLista() {
        let store = BookStore()
        let viewModel = FavoritesViewModel(store: store)
        store.toggleFavorite(store.books[1])

        viewModel.removeFavorite(store.books[1])

        #expect(viewModel.isEmpty == true)
    }

    @Test func quitarUnLibroQueNoEsFavoritoNoLoAgrega() {
        let store = BookStore()
        let viewModel = FavoritesViewModel(store: store)

        viewModel.removeFavorite(store.books[0])

        #expect(viewModel.isEmpty == true)
    }
}
