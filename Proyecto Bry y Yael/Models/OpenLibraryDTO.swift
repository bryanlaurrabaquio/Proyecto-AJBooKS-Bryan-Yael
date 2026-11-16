
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

    func toBook() -> Book {
        let authors = (authorName ?? []).filter {
            !$0.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
        }

        let author = authors.isEmpty
        ? "Autor desconocido"
        : authors.joined(separator: ", ")

        let genre = subject?.first {
            !$0.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
        }

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
