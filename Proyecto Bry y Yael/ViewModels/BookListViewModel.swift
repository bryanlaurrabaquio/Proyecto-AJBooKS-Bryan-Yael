
import Foundation
import Observation

@MainActor
@Observable
final class BookListViewModel {

    static let featuredQuery = "subject:classics"

    private let store: BookStore
    private let service: any BookServicing

    var searchText = ""

    init(
    store: BookStore,
    service: any BookServicing = OpenLibraryService()
    ) {
        self.store = store
        self.service = service
    }

    // Se lee directamente del BookStore.
    var state: LoadState {
        store.catalogState
    }

    var books: [Book] {
        store.books
    }

    // Búsqueda local sobre los libros descargados.
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

    var favoritesCount: Int {
        store.favorites.count
    }

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
            store.catalogState = .error(
                .unknown(String(describing: error))
            )
        }
    }
}
