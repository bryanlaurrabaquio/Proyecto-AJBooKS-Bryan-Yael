import Foundation

// Lógica de presentación de las descripciones, compartida por los tres ViewModels.
// Las vistas solo dibujan estos valores; no deciden qué texto mostrar.

// Lo que se ve en la tarjeta de la lista.
enum DescriptionPreview: Equatable {
    case loading
    // Resumen en español (la tarjeta lo limita a unas líneas; el detalle muestra el texto completo).
    case summary(String)
    // Aviso cuando no hay texto en español.
    case notice(String)
}

// Lo que se ve en la pantalla de detalle.
enum DetailDescriptionContent: Equatable {
    case loading
    case text(String)
    // Solo existe en otro idioma: se informa y se ofrece la traducción del sistema.
    case onlyInOtherLanguage(languageName: String, original: String)
    case unavailable
    case failed
}

extension DescriptionState {

    var preview: DescriptionPreview {
        switch self {
        case .idle, .loading:
            return .loading

        case .loaded(.spanish(let text)):
            // En la tarjeta los párrafos se unen para aprovechar las líneas disponibles.
            let singleLine = text
                .replacingOccurrences(of: "\\s*\\n+\\s*", with: " ", options: .regularExpression)
            return .summary(singleLine)

        case .loaded(.otherLanguage(_, let code)):
            let language = LanguageDetector.spanishName(forLanguageCode: code)
            return .notice("Descripción disponible solo en \(language)")

        case .loaded(.unavailable):
            return .notice("Descripción no disponible")

        case .failed:
            return .notice("No se pudo cargar la descripción")
        }
    }

    var detailContent: DetailDescriptionContent {
        switch self {
        case .idle, .loading:
            return .loading

        case .loaded(.spanish(let text)):
            return .text(text)

        case .loaded(.otherLanguage(let text, let code)):
            return .onlyInOtherLanguage(
                languageName: LanguageDetector.spanishName(forLanguageCode: code),
                original: text
            )

        case .loaded(.unavailable):
            return .unavailable

        case .failed:
            return .failed
        }
    }
}
