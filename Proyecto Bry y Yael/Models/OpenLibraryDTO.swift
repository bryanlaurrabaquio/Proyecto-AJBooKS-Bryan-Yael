import Foundation

// MARK: - Búsqueda (GET /search.json)

// Modelos que reflejan el JSON de Open Library. Solo se usan para decodificar;
// la app trabaja con `Book`, que se arma en `toBook()` ya con el texto limpio.
struct OpenLibrarySearchResponse: Decodable {
    let docs: [OpenLibraryDocument]
}

struct OpenLibraryDocument: Decodable {
    let key: String
    // Opcional: si un documento llega sin título se descarta en lugar de romper toda la respuesta.
    let title: String?
    let authorName: [String]?
    let firstPublishYear: Int?
    let subject: [String]?
    let coverI: Int?
    // Mejor edición de la obra según el parámetro `lang` (de preferencia, en español).
    let editions: OpenLibraryEditionList?

    // Convierte el documento al modelo de la app.
    // Devuelve nil si no hay un título que mostrar.
    func toBook() -> Book? {
        let spanishEdition = editions?.docs.first { $0.isSpanish }
        let shownEdition = spanishEdition ?? editions?.docs.first

        // Se prefiere el título de la edición en español; si no existe se conserva el original.
        let spanishTitle = TextSanitizer.cleanTitle(spanishEdition?.title ?? "")
        let originalTitle = TextSanitizer.cleanTitle(title ?? "")
        let shownTitle = spanishTitle.isEmpty ? originalTitle : spanishTitle

        guard !shownTitle.isEmpty else {
            return nil
        }

        // Los nombres de autor se limpian, pero no se traducen ni se reordenan.
        var authors: [String] = []
        for name in authorName ?? [] {
            let cleaned = TextSanitizer.cleanInline(name)
            if !cleaned.isEmpty && !authors.contains(cleaned) {
                authors.append(cleaned)
            }
        }

        let author = authors.isEmpty
        ? "Autor desconocido"
        : authors.joined(separator: ", ")

        // La portada de la edición en español coincide con el título mostrado;
        // si esa edición no tiene portada se usa la de la obra.
        let cover = validCover(spanishEdition?.coverI) ?? validCover(coverI)

        return Book(
            id: key,
            title: shownTitle,
            author: author,
            year: firstPublishYear,
            genre: SubjectGenreMapper.spanishGenre(from: subject ?? []),
            description: "",
            coverID: cover,
            editionKey: shownEdition?.key
        )
    }

    // Open Library usa -1 (o no envía el campo) cuando no hay portada.
    private func validCover(_ id: Int?) -> Int? {
        guard let id, id > 0 else { return nil }
        return id
    }
}

struct OpenLibraryEditionList: Decodable {
    let docs: [OpenLibraryEdition]
}

struct OpenLibraryEdition: Decodable {
    let key: String
    let title: String?
    // Códigos MARC de idioma, por ejemplo ["spa"].
    let language: [String]?
    let coverI: Int?

    var isSpanish: Bool {
        language?.contains(OpenLibraryService.spanishLanguageCode) ?? false
    }
}

// MARK: - Obra o edición (GET /works/{id}.json y /books/{id}.json)

// Solo se decodifica la descripción; el resto del registro no se usa.
struct OpenLibraryRecord: Decodable {
    let description: OpenLibraryText?

    // Descripción limpia (sin HTML, Markdown ni espacios sobrantes). nil si no hay texto.
    var cleanedDescription: String? {
        guard let raw = description?.value else { return nil }
        let cleaned = TextSanitizer.cleanParagraphs(raw)
        return cleaned.isEmpty ? nil : cleaned
    }
}

// Open Library entrega los textos largos de dos formas:
//   "description": "texto"
//   "description": { "type": "/type/text", "value": "texto" }
struct OpenLibraryText: Decodable {
    let value: String

    private enum CodingKeys: String, CodingKey {
        case value
    }

    init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(),
           let text = try? single.decode(String.self) {
            value = text
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        value = try container.decode(String.self, forKey: .value)
    }
}
