
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
            description: ""
        )
    }
}
