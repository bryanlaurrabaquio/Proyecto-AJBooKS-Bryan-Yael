import Foundation
import Observation

// ViewModel de Detalle: trabaja con un solo libro, su estado de "guardado" y su descripción.
@MainActor
@Observable
final class BookDetailViewModel {
    private let store: BookStore
    let book: Book

    init(book: Book, store: BookStore) {
        self.book = book
        self.store = store
    }

    // MARK: - Favorito

    // Se lee del BookStore, no se guarda una copia aquí.
    var isSaved: Bool {
        return store.isFavorite(book)
    }

    var buttonTitle: String {
        if isSaved {
            return "Guardado"
        }
        return "Guardar"
    }

    // Texto que lee VoiceOver en el botón.
    var buttonAccessibilityLabel: String {
        if isSaved {
            return "Quitar de favoritos"
        }
        return "Guardar en favoritos"
    }

    func toggleSaved() {
        store.toggleFavorite(book)
    }

    // MARK: - Descripción

    var descriptionState: DescriptionState {
        store.descriptionState(for: book)
    }

    var descriptionContent: DetailDescriptionContent {
        descriptionState.detailContent
    }

    // Texto plano de la descripción (o el motivo por el que no hay).
    var descriptionText: String {
        switch descriptionContent {
        case .text(let text):
            return text
        case .loading:
            return "Cargando descripción…"
        case .onlyInOtherLanguage(let language, _):
            return "Open Library no tiene una descripción en español para este libro; solo está disponible en \(language)."
        case .unavailable:
            return "Descripción no disponible."
        case .failed:
            return "No se pudo cargar la descripción."
        }
    }

    func loadDescription() async {
        await store.loadDescription(for: book)
    }

    func retryDescription() async {
        await store.reloadDescription(for: book)
    }

    // MARK: - Datos del libro

    // Textos para mostrar cuando la API no entregó el dato.
    var yearText: String {
        book.year.map { String($0) } ?? "Desconocido"
    }

    var genreText: String {
        book.genre ?? "Sin género"
    }

    var coverAccessibilityLabel: String {
        "Portada de " + book.title
    }
}
