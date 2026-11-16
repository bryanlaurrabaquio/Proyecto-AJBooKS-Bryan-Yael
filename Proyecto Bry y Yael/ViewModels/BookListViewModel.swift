
import Foundation
import Observation

@MainActor
@Observable
final class BookListViewModel {

    static let featuredQuery = "subject:classics"

    // Temas de Open Library que se eligen al azar cada vez que se jala la pantalla.
    static let randomSubjects = [
        "classics", "fantasy", "history", "science", "romance",
        "mystery", "adventure", "poetry", "philosophy", "horror",
        "science_fiction", "biography", "art", "travel"
    ]

    // Posición máxima desde la que se piden libros al azar dentro de un tema.
    static let maxRandomOffset = 1000

    // Cuántos libros se muestran a la vez en la pantalla de inicio.
    static let visibleBooksCount = 10

    private let store: BookStore
    private let service: any BookServicing

    var searchText = ""

    // Libros descargados del tema actual. De aquí se sacan los 10 al azar.
    private var allBooks: [Book] = []

    // Resultado de buscar en toda la base de Open Library (al presionar "Buscar").
    // .idle significa que no hay una búsqueda activa.
    private(set) var searchState: LoadState = .idle

    // Texto de la búsqueda en curso, para ignorar respuestas viejas.
    private var activeQuery = ""

    // Último tema consultado, para no repetirlo en el siguiente refresco.
    private var lastSubject = "classics"

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

    // Búsqueda local sobre todos los libros descargados.
    var filteredBooks: [Book] {
        let text = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        // Sin texto se muestran los 10 libros al azar.
        if text.isEmpty {
            return books
        }

        // Con texto se busca en todos los libros descargados, no solo en los 10 visibles.
        // Si todavía no hay libros descargados, se usan los que están en el store.
        let source = allBooks.isEmpty ? books : allBooks

        return source.filter { book in
            book.title.localizedStandardContains(text)
            || book.author.localizedStandardContains(text)
        }
    }

    // Verdadero cuando la pantalla debe mostrar resultados de Open Library.
    var isShowingSearchResults: Bool {
        if case .idle = searchState {
            return false
        }

        return true
    }

    // Se llama al presionar "Buscar" en el teclado: consulta toda la base de Open Library.
    func search() async {
        let text = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if text.isEmpty {
            resetSearch()
            return
        }

        activeQuery = text
        searchState = .loading

        do {
            let found = try await service.fetchBooks(query: text)

            // Si el usuario cambió el texto mientras esperaba, se ignora esta respuesta.
            guard activeQuery == text else { return }

            searchState = found.isEmpty ? .empty : .content(found)

        } catch is CancellationError {
            if activeQuery == text {
                searchState = .idle
            }

        } catch let error as BookServiceError {
            guard activeQuery == text else { return }
            searchState = .error(error)

        } catch {
            guard activeQuery == text else { return }
            searchState = .error(.unknown)
        }
    }

    // Se llama cuando el usuario edita el texto: vuelve a la lista de inicio.
    func resetSearch() {
        activeQuery = ""
        searchState = .idle
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

    // Se llama al jalar la pantalla hacia abajo: pide a la API un tema distinto
    // al azar, desde una posición al azar, y muestra 10 libros de ese tema.
    // No se pone el estado en .loading: así la lista no desaparece mientras
    // se espera y el indicador de refresco de iOS se encarga de avisar.
    func refreshRandomBooks() async {
        // Si todavía no hay libros descargados, se intenta la carga normal.
        if allBooks.isEmpty {
            await loadBooks()
            return
        }

        let subject = Self.randomSubjects
            .filter { $0 != lastSubject }
            .randomElement() ?? Self.randomSubjects[0]

        let query = "subject:" + subject

        do {
            // Se empieza en una posición al azar dentro del tema, no siempre
            // en los primeros resultados.
            var downloaded = try await service.fetchBooks(
                query: query,
                offset: Int.random(in: 0..<Self.maxRandomOffset)
            )

            // Si el tema tiene menos libros que esa posición, se piden los primeros.
            if downloaded.isEmpty {
                downloaded = try await service.fetchBooks(query: query, offset: 0)
            }

            try Task.checkCancellation()

            // Si el tema no trae libros, se dejan los que ya se ven.
            if downloaded.isEmpty {
                return
            }

            lastSubject = subject
            allBooks = downloaded
            store.catalogState = .content(randomBooks())

        } catch {
            // Si falla el refresco (sin internet, por ejemplo), se conservan
            // los libros que ya estaban en pantalla.
        }
    }

    // Elige 10 libros al azar, procurando que no se repitan los que ya se ven.
    private func randomBooks() -> [Book] {
        let currentIDs = Set(store.books.map { $0.id })
        let newOnes = allBooks.filter { !currentIDs.contains($0.id) }

        // Si ya no quedan suficientes libros distintos, se usan todos.
        let candidates = newOnes.count >= Self.visibleBooksCount ? newOnes : allBooks

        return Array(candidates.shuffled().prefix(Self.visibleBooksCount))
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

            allBooks = downloadedBooks

            if downloadedBooks.isEmpty {
                store.catalogState = .empty
            } else {
                // Al inicio solo se muestran 10 libros al azar.
                store.catalogState = .content(randomBooks())
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
