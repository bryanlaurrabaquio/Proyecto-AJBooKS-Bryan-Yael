import Foundation

// Resultado de buscar la descripción de un libro en la fuente de datos.
// Distingue entre "hay texto en español", "solo hay texto en otro idioma" y "no hay texto",
// para que la interfaz nunca presente un texto en inglés como si fuera la sinopsis en español.
nonisolated enum BookDescription: Equatable {
    // Descripción en español, ya limpia.
    case spanish(String)
    // La fuente solo tiene la descripción en otro idioma (código ISO 639-1, p. ej. "en").
    // Se conserva el texto original para ofrecer la traducción del sistema a petición del usuario.
    case otherLanguage(text: String, languageCode: String?)
    // La fuente no tiene descripción utilizable.
    case unavailable
}

// Estado de la consulta de la descripción de un libro (se guarda por libro en BookStore).
nonisolated enum DescriptionState: Equatable {
    case idle
    case loading
    case loaded(BookDescription)
    case failed
}

nonisolated extension BookDescription {
    // Textos más cortos que esto suelen ser créditos editoriales ("Edición de ...")
    // y no una descripción del libro, así que no se muestran como sinopsis.
    static let minimumLength = 60

    // Elige la mejor descripción disponible a partir de los textos YA LIMPIOS de la edición y de la obra.
    // Prioridad:
    //   1. Texto en español de la edición (es la edición que se muestra).
    //   2. Texto en español de la obra.
    //   3. Texto en otro idioma (primero el de la obra, que suele ser el más completo).
    //   4. Sin descripción.
    // `languageOf` se inyecta para poder probar la regla sin depender del detector real.
    static func select(
        editionText: String?,
        workText: String?,
        languageOf detectLanguage: (String) -> String? = LanguageDetector.languageCode
    ) -> BookDescription {
        let edition = usable(editionText)
        let work = usable(workText)

        var detected: [(text: String, code: String?)] = []

        for text in [edition, work].compactMap({ $0 }) {
            let code = detectLanguage(text)
            if code == LanguageDetector.spanishCode {
                return .spanish(text)
            }
            detected.append((text, code))
        }

        // Ningún texto está en español: se prefiere el de la obra.
        if let fallback = detected.last {
            return .otherLanguage(text: fallback.text, languageCode: fallback.code)
        }

        return .unavailable
    }

    private static func usable(_ text: String?) -> String? {
        guard let text else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= minimumLength ? trimmed : nil
    }
}
