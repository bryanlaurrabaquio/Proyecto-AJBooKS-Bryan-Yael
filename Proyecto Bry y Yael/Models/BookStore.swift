import Foundation
import Observation

// Fuente única de verdad: el catálogo remoto (según el estado de la consulta a la API),
// las descripciones ya consultadas y los favoritos guardados en SwiftData.
@MainActor
@Observable
final class BookStore {

    // Fuente única de verdad del catálogo remoto.
    var catalogState: LoadState = .idle

    // Los libros se obtienen del estado de la API.
    var books: [Book] {
        if case .content(let items) = catalogState {
            return items
        }
        return []
    }

    // Favoritos guardados en SwiftData.
    private(set) var favoriteRecords: [FavoriteBook] = []

    var favoriteIDs: [String] {
        favoriteRecords.map { $0.bookID }
    }

    // Se reconstruyen desde los datos persistidos.
    // No dependen de los resultados de Open Library.
    var favorites: [Book] {
        favoriteRecords.map { $0.toBook() }
    }

    // Descripciones por id de libro. Las comparten la lista, el detalle y Favoritos,
    // así cada descripción se descarga una sola vez por sesión.
    private(set) var descriptionStates: [String: DescriptionState] = [:]

    // Descargas en curso (no se observan: no afectan a la interfaz).
    @ObservationIgnored
    private var descriptionTasks: [String: Task<Void, Never>] = [:]

    private let favoritesService: any FavoritesServiceProtocol
    private let descriptionService: any BookDescriptionServicing

    // Si no se indica un servicio de descripciones se usa Open Library.
    // (Se crea dentro del init para hacerlo en el MainActor.)
    init(
        favoritesService: any FavoritesServiceProtocol =
        InMemoryFavoritesService(),
        descriptionService: (any BookDescriptionServicing)? = nil
    ) {
        self.favoritesService = favoritesService
        self.descriptionService = descriptionService ?? OpenLibraryService()
        loadFavorites()
    }

    // MARK: - Favoritos

    func isFavorite(_ book: Book) -> Bool {
        favoriteIDs.contains(book.id)
    }

    func toggleFavorite(_ book: Book) {
        if isFavorite(book) {
            favoritesService.removeFavorite(book: book)
        } else {
            favoritesService.saveFavorite(book: book)
        }

        loadFavorites()
    }

    func loadFavorites() {
        favoriteRecords =
        favoritesService.fetchFavorites() ?? []
    }

    // MARK: - Descripciones

    func descriptionState(for book: Book) -> DescriptionState {
        if let state = descriptionStates[book.id] {
            return state
        }

        // Un libro que ya trae su descripción (por ejemplo, en las vistas previas) no necesita red.
        let preloaded = TextSanitizer.cleanParagraphs(book.description)
        return preloaded.isEmpty ? .idle : .loaded(.spanish(preloaded))
    }

    // Empieza a descargar la descripción si todavía no se ha pedido.
    // La descarga no depende de la vista que la pidió: si la tarjeta sale de la pantalla,
    // la descarga termina igual y el resultado queda disponible para el detalle.
    @discardableResult
    func requestDescription(for book: Book) -> Task<Void, Never>? {
        if let running = descriptionTasks[book.id] {
            return running
        }

        guard case .idle = descriptionState(for: book) else {
            return nil
        }

        descriptionStates[book.id] = .loading
        let service = descriptionService

        let task = Task { [weak self] in
            let newState: DescriptionState
            do {
                newState = .loaded(try await service.fetchDescription(for: book))
            } catch {
                newState = .failed
            }
            self?.finishDescription(for: book.id, with: newState)
        }

        descriptionTasks[book.id] = task
        return task
    }

    // Igual que requestDescription, pero espera a que termine (lo usan el detalle y las pruebas).
    func loadDescription(for book: Book) async {
        await requestDescription(for: book)?.value
    }

    // Vuelve a intentar después de un error.
    func reloadDescription(for book: Book) async {
        if descriptionTasks[book.id] == nil {
            descriptionStates[book.id] = nil
        }
        await loadDescription(for: book)
    }

    private func finishDescription(for id: String, with state: DescriptionState) {
        descriptionStates[id] = state
        descriptionTasks[id] = nil
    }
}
