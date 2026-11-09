import Testing
@testable import Proyecto_Bry_y_Yael

// Pruebas de la lógica de la aplicación.
// Utilizan libros simulados sin depender de internet.
@MainActor
struct Proyecto_Bry_y_YaelTests {

    // MARK: - Book

    @Test func subtitleUneAnioYGenero() {
        // Arrange
        let book = Book(
            id: "local-frankenstein",
            title: "Frankenstein",
            author: "Mary Shelley",
            year: 1818,
            genre: "Terror",
            description: ""
        )

        // Act
        let subtitle = book.subtitle

        // Assert
        #expect(subtitle == "1818 - Terror")
    }

    @Test func subtitleSinAnioMuestraSoloElGenero() {
        // Arrange
        let book = Book(
            id: "local-odisea",
            title: "La Odisea",
            author: "Homero",
            year: nil,
            genre: "Aventura",
            description: ""
        )

        // Assert
        #expect(book.subtitle == "Aventura")
    }

    @Test func subtitleSinAnioNiGeneroEsNil() {
        // Arrange
        let book = Book(
            id: "local-sin-datos",
            title: "Libro sin datos",
            author: "Autor",
            year: nil,
            genre: nil,
            description: ""
        )

        // Assert
        #expect(book.subtitle == nil)
    }

    // MARK: - Favoritos con datos opcionales

    @Test func favoritoConservaLosDatosQueFaltan() {
        // Arrange
        let store = makeSeededStore()
        let sinAnio = Book(
            id: "local-sin-anio",
            title: "Sin año",
            author: "Autor",
            year: nil,
            genre: nil,
            description: ""
        )

        // Act
        store.toggleFavorite(sinAnio)

        // Assert: lo que no existía sigue siendo nil (no se inventan valores).
        #expect(store.favorites.count == 1)
        #expect(store.favorites[0].year == nil)
        #expect(store.favorites[0].genre == nil)
    }

    @Test func favoritoConservaAnioYGenero() {
        // Arrange
        let store = makeSeededStore()
        let frankenstein = store.books[5]

        // Act
        store.toggleFavorite(frankenstein)

        // Assert
        #expect(store.favorites[0].year == 1818)
        #expect(store.favorites[0].genre == "Terror")
    }

    // MARK: - BookListViewModel

    @Test func sinBusquedaMuestraTodosLosLibros() {
        // Arrange
        let store = makeSeededStore()
        let viewModel = BookListViewModel(store: store)

        // Act
        let result = viewModel.filteredBooks

        // Assert
        #expect(result.count == store.books.count)
        #expect(result.count == 6)
        #expect(viewModel.noResults == false)
    }

    // La búsqueda no distingue mayúsculas de minúsculas.
    @Test(arguments: [
    "odisea",
    "ODISEA",
    "Odisea",
    "OdIsEa"
    ])
    func busquedaNoDistingueMayusculas(texto: String) {
        // Arrange
        let viewModel = BookListViewModel(
            store: makeSeededStore()
        )

        // Act
        viewModel.searchText = texto

        // Assert
        #expect(viewModel.filteredBooks.count == 1)
        #expect(viewModel.filteredBooks[0].title == "La Odisea")
    }

    // La búsqueda ignora diferencias de acentos.
    @Test(arguments: [
    "paramo",
    "PARAMO",
    "páramo",
    "Páramo"
    ])
    func busquedaNoDistingueAcentos(texto: String) {
        // Arrange
        let viewModel = BookListViewModel(
            store: makeSeededStore()
        )

        // Act
        viewModel.searchText = texto

        // Assert
        #expect(viewModel.filteredBooks.count == 1)
        #expect(viewModel.filteredBooks[0].title == "Pedro Páramo")
    }

    // Una búsqueda sin coincidencias devuelve una lista vacía.
    @Test(arguments: [
    "zzzz",
    "xyz",
    "12345"
    ])
    func busquedaSinCoincidenciasActivaNoResults(texto: String) {
        // Arrange
        let viewModel = BookListViewModel(
            store: makeSeededStore()
        )

        // Act
        viewModel.searchText = texto

        // Assert
        #expect(viewModel.filteredBooks.isEmpty)
        #expect(viewModel.noResults == true)
    }

    // MARK: - Contador de favoritos

    @Test func favoritesCountSigueAlStore() {
        // Arrange
        let store = makeSeededStore()
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
        let store = makeSeededStore()

        let viewModel = BookDetailViewModel(
            book: store.books[0],
            store: store
        )

        #expect(viewModel.isSaved == false)
        #expect(viewModel.buttonTitle == "Guardar")
        #expect(
            viewModel.buttonAccessibilityLabel
            == "Guardar en favoritos"
        )

        // Act
        viewModel.toggleSaved()

        // Assert
        #expect(viewModel.isSaved == true)
        #expect(viewModel.buttonTitle == "Guardado")
        #expect(
            viewModel.buttonAccessibilityLabel
            == "Quitar de favoritos"
        )
        #expect(store.isFavorite(store.books[0]))
    }

    @Test func detalleMuestraTextoCuandoFaltanAnioOGenero() {
        // Arrange
        let store = makeSeededStore()
        let sinDatos = Book(
            id: "local-sin-datos",
            title: "Libro sin datos",
            author: "Autor",
            year: nil,
            genre: nil,
            description: ""
        )

        // Act
        let viewModel = BookDetailViewModel(book: sinDatos, store: store)

        // Assert
        #expect(viewModel.yearText == "Desconocido")
        #expect(viewModel.genreText == "Sin género")
    }

    // MARK: - FavoritesViewModel

    @Test func favoritosEmpiezaVacioYSeActualizaConElStore() {
        // Arrange
        let store = makeSeededStore()
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
        let store = makeSeededStore()
        let viewModel = FavoritesViewModel(store: store)

        store.toggleFavorite(store.books[1])

        // Act
        viewModel.removeFavorite(store.books[1])

        // Assert
        #expect(viewModel.isEmpty == true)
    }

    @Test func quitarUnLibroQueNoEsFavoritoNoLoAgrega() {
        // Arrange
        let store = makeSeededStore()
        let viewModel = FavoritesViewModel(store: store)

        // Act
        viewModel.removeFavorite(store.books[0])

        // Assert
        #expect(viewModel.isEmpty == true)
    }
}
