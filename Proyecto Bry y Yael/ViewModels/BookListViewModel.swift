import Foundation
import Observation

@MainActor
@Observable
final class BookListViewModel {

    // Clásicos de la literatura. El servicio agrega el filtro de ediciones en español.
    static let featuredQuery = "subject:classics"

    private let store: BookStore
    private let service: any BookServicing

    var searchText = ""

    // Si no se indica un servicio se usa Open Library.
    // (Se crea dentro del init para hacerlo en el MainActor.)
    init(
        store: BookStore,
        service: (any BookServicing)? = nil
    ) {
        self.store = store
        self.service = service ?? OpenLibraryService()
    }

    // Se lee directamente del BookStore.
    var state: LoadState {
        store.catalogState
    }

    var books: [Book] {
        store.books
    }

    // Búsqueda local sobre los libros descargados.
    // No distingue mayúsculas ni acentos ("paramo" encuentra "Páramo").
    var filteredBooks: [Book] {
        let text = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if text.isEmpty {
            return books
        }

        return books.filter { book in
            book.title.localizedStandardContains(text)
            || book.author.localizedStandardContains(text)
        }
    }

    // Solo se considera "sin coincidencias"
    // cuando la API sí entregó libros.
    var noResults: Bool {
        if case .content = state {
            return filteredBooks.isEmpty
        }

        return false
    }

    var noResultsMessage: String {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return "No se encontraron libros para “\(text)”"
    }

    // Texto bajo el buscador: cuántos libros se están mostrando.
    var resultsSummary: String {
        let count = filteredBooks.count
        return count == 1 ? "1 libro" : "\(count) libros"
    }

    var favoritesCount: Int {
        store.favorites.count
    }

    var favoritesAccessibilityLabel: String {
        favoritesCount == 1
        ? "Ver favoritos, 1 libro guardado"
        : "Ver favoritos, \(favoritesCount) libros guardados"
    }

    // MARK: - Favoritos desde la tarjeta

    func isFavorite(_ book: Book) -> Bool {
        store.isFavorite(book)
    }

    func toggleFavorite(_ book: Book) {
        store.toggleFavorite(book)
    }

    // MARK: - Descripciones de las tarjetas

    func descriptionPreview(for book: Book) -> DescriptionPreview {
        store.descriptionState(for: book).preview
    }

    // Se llama cuando la tarjeta aparece en pantalla (carga perezosa).
    func prefetchDescription(for book: Book) {
        store.requestDescription(for: book)
    }

    // MARK: - Catálogo

    // Evita descargar repetidamente el catálogo.
    func loadIfNeeded() async {
        if case .idle = state {
            await loadBooks()
        }
    }

    func retry() async {
        await loadBooks()
    }

    func loadBooks() async {

        if case .loading = state {
            return
        }

        store.catalogState = .loading

        do {
            let downloadedBooks = try await service.fetchBooks(
                query: Self.featuredQuery
            )

            try Task.checkCancellation()

            if downloadedBooks.isEmpty {
                store.catalogState = .empty
            } else {
                store.catalogState = .content(downloadedBooks)
            }

        } catch is CancellationError {
            store.catalogState = .idle

        } catch let error as BookServiceError {
            store.catalogState = .error(error)

        } catch {
            store.catalogState = .error(.unknown)
        }
    }
}
