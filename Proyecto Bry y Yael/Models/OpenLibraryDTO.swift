
import Foundation

struct OpenLibrarySearchResponse: Decodable {
    let docs: [OpenLibraryDocument]
}

struct OpenLibraryDocument: Decodable {
    let key: String
    let title: String
    let authorName: [String]?
    let firstPublishYear: Int?
    let subject: [String]?
    let coverI: Int?

    // Open Library no tiene un campo "género": solo etiquetas (subject) que escribe
    // cualquier usuario, y a veces son cosas como "bible" o "nyt:combined-print-...".
    // Asi que solo se acepta como género una etiqueta que esté en esta lista (en minúsculas).
    static let knownGenres: Set<String> = [
        "fiction", "science fiction", "fantasy", "mystery", "romance", "horror",
        "thriller", "adventure", "historical fiction", "classic literature",
        "classics", "poetry", "drama", "short stories", "essays", "humor",
        "biography", "autobiography", "history", "philosophy", "science",
        "psychology", "religion", "art", "travel", "self-help",
        "novela", "poesía", "historia", "ficción"
    ]

    func toBook() -> Book {
        let authors = (authorName ?? []).filter {
            !$0.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
        }

        let author = authors.isEmpty
        ? "Autor desconocido"
        : authors.joined(separator: ", ")

        // Primera etiqueta que sea un género conocido; si no hay ninguna, queda en nil.
        let genre = (subject ?? [])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { Self.knownGenres.contains($0.lowercased()) }

        return Book(
            id: key,
            title: title,
            author: author,
            year: firstPublishYear,
            genre: genre,
            description: "",
            coverID: coverI
        )
    }
}

struct OpenLibraryWork: Decodable {
    let description: OpenLibraryText?

    var cleanDescription: String {
        (description?.value ?? "")
            .components(separatedBy: "----------")[0]
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct OpenLibraryText: Decodable {
    let value: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let text = try? container.decode(String.self) {
            value = text
        } else {
            value = try container.decode([String: String].self)["value"] ?? ""
        }
    }
}
