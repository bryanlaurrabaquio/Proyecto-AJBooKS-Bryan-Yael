import Testing
@testable import Proyecto_Bry_y_Yael

// Pruebas de la lógica que salió de las vistas: se prueban sin abrir la interfaz.
@MainActor
struct Proyecto_Bry_y_YaelTests {

    // MARK: - Book

    @Test func subtitleUneAnioYGenero() {
        // Arrange
        let book = Book(id: "local-frankenstein", title: "Frankenstein", author: "Mary Shelley", year: "1818", genre: "Terror", description: "")

        // Act
        let subtitle = book.subtitle

        // Assert
        #expect(subtitle == "1818 - Terror")
    }

    // MARK: - BookListViewModel

    @Test func sinBusquedaMuestraTodosLosLibros() {
        // Arrange
        let store = BookStore()
        let viewModel = BookListViewModel(store: store)

        // Act
        let result = viewModel.filteredBooks

        // Assert
        #expect(result.count == store.books.count)
        #expect(viewModel.noResults == false)
    }

    // Parametrizada: la misma prueba con distintas formas de escribir "La Odisea".
    @Test(arguments: [
        "odisea",
        "ODISEA",
        "Odisea",
        "OdIsEa"
    ])
    func busquedaNoDistingueMayusculas(texto: String) {
        // Arrange
        let viewModel = BookListViewModel(store: BookStore())

        // Act
        viewModel.searchText = texto

        // Assert
        #expect(viewModel.filteredBooks.count == 1)
        #expect(viewModel.filteredBooks[0].title == "La Odisea")
    }

    // Parametrizada: con o sin acento debe encontrar "Pedro Páramo".
    @Test(arguments: [
        "paramo",
        "PARAMO",
        "páramo",
        "Páramo"
    ])
    func busquedaNoDistingueAcentos(texto: String) {
        // Arrange
        let viewModel = BookListViewModel(store: BookStore())

        // Act
        viewModel.searchText = texto

        // Assert
        #expect(viewModel.filteredBooks.count == 1)
        #expect(viewModel.filteredBooks[0].title == "Pedro Páramo")
    }

    // Parametrizada: textos que no coinciden con ningún título.
    @Test(arguments: [
        "zzzz",
        "xyz",
        "12345"
    ])
    func busquedaSinCoincidenciasActivaNoResults(texto: String) {
        // Arrange
        let viewModel = BookListViewModel(store: BookStore())

        // Act
        viewModel.searchText = texto

        // Assert
        #expect(viewModel.filteredBooks.isEmpty)
        #expect(viewModel.noResults == true)
    }

    @Test func favoritesCountSigueAlStore() {
        // Arrange
        let store = BookStore()
        let viewModel = BookListViewModel(store: store)
        #expect(viewModel.favoritesCount == 0)

        // Act
        store.toggleFavorite(store.books[0])

        // Assert
        #expect(viewModel.favoritesCount == 1)
    }

    // MARK: - BookDetailViewModel

    @Test func detalleAlternaGuardadoYTextoDelBoton() {
        // Arrange
        let store = BookStore()
        let viewModel = BookDetailViewModel(book: store.books[0], store: store)
        #expect(viewModel.isSaved == false)
        #expect(viewModel.buttonTitle == "Guardar")
        #expect(viewModel.buttonAccessibilityLabel == "Guardar en favoritos")

        // Act
        viewModel.toggleSaved()

        // Assert
        #expect(viewModel.isSaved == true)
        #expect(viewModel.buttonTitle == "Guardado")
        #expect(viewModel.buttonAccessibilityLabel == "Quitar de favoritos")
        #expect(store.isFavorite(store.books[0]))
    }

    // MARK: - FavoritesViewModel

    @Test func favoritosEmpiezaVacioYSeActualizaConElStore() {
        // Arrange
        let store = BookStore()
        let viewModel = FavoritesViewModel(store: store)
        #expect(viewModel.isEmpty == true)

        // Act
        store.toggleFavorite(store.books[1])

        // Assert
        #expect(viewModel.isEmpty == false)
        #expect(viewModel.favorites.count == 1)
    }

    @Test func quitarFavoritoLoSacaDeLaLista() {
        // Arrange
        let store = BookStore()
        let viewModel = FavoritesViewModel(store: store)
        store.toggleFavorite(store.books[1])

        // Act
        viewModel.removeFavorite(store.books[1])

        // Assert
        #expect(viewModel.isEmpty == true)
    }

    @Test func quitarUnLibroQueNoEsFavoritoNoLoAgrega() {
        // Arrange
        let store = BookStore()
        let viewModel = FavoritesViewModel(store: store)

        // Act
        viewModel.removeFavorite(store.books[0])

        // Assert
        #expect(viewModel.isEmpty == true)
    }
}
