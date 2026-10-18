import Testing
@testable import Proyecto_Bry_y_Yael

struct Proyecto_Bry_y_YaelTests {
        // MARK: - Book (Model)

    @Test func bookMatchesIgnoringCase() {
        let book = BookStore().books[0] // La Odisea
        #expect(book.matches("odisea"))
        #expect(book.matches("ODISEA"))
        #expect(!book.matches("Quijote"))
    }

    // MARK: - BookListViewModel (ViewModel de Inicio)

    @Test func emptySearchShowsAllBooks() {
        let store = BookStore()
        let viewModel = BookListViewModel()
        #expect(viewModel.filteredBooks(from: store.books).count == 6)
    }

    @Test func searchFiltersByTitle() {
        let store = BookStore()
        let viewModel = BookListViewModel()
        viewModel.searchText = "pedro"
        #expect(viewModel.filteredBooks(from: store.books).map(\.title) == ["Pedro Páramo"])
    }

    @Test func searchIgnoresSurroundingSpaces() {
        let store = BookStore()
        let viewModel = BookListViewModel()
        viewModel.searchText = "  odisea "
        #expect(viewModel.filteredBooks(from: store.books).map(\.title) == ["La Odisea"])

        viewModel.searchText = "   "
        #expect(viewModel.filteredBooks(from: store.books).count == 6)
    }

    @Test func searchWithoutResultsIsEmpty() {
        let store = BookStore()
        let viewModel = BookListViewModel()
        viewModel.searchText = "zzz"
        #expect(viewModel.filteredBooks(from: store.books).isEmpty)
    }

    // MARK: - BookStore (estado compartido)

    @Test func favoritesStartEmpty() {
        #expect(BookStore().favoriteBooks.isEmpty)
    }

    @Test func toggleFavoriteAddsAndRemoves() {
        let store = BookStore()
        let book = store.books[1]

        store.toggleFavorite(book)
        #expect(store.isFavorite(book))
        #expect(store.favoriteBooks.map(\.id) == [book.id])

        store.toggleFavorite(book)
        #expect(!store.isFavorite(book))
        #expect(store.favoriteBooks.isEmpty)
    }

    @Test func favoritesKeepCatalogOrder() {
        let store = BookStore()
        store.toggleFavorite(store.books[5])
        store.toggleFavorite(store.books[0])
        #expect(store.favoriteBooks.map(\.id) == [store.books[0].id, store.books[5].id])
    }
}
