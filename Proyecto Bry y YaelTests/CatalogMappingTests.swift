import Foundation
import Testing
@testable import Proyecto_Bry_y_Yael

// Pruebas del mapeo de la búsqueda de Open Library al modelo `Book`:
// edición en español, portadas, géneros en español y limpieza de texto.
@MainActor
struct CatalogMappingTests {

    // Respuesta con la forma real de /search.json (campos `editions` y `cover_i`).
    private let searchJSON = #"""
    {
      "docs": [
        {
          "key": "/works/OL1W",
          "title": "Das Schloß",
          "author_name": ["Franz Kafka", "Franz Kafka"],
          "first_publish_year": 1926,
          "subject": ["Fiction", "Bureaucracy"],
          "cover_i": 111,
          "editions": {
            "numFound": 1, "start": 0, "numFoundExact": true,
            "docs": [
              { "key": "/books/OL9M", "title": "El castillo /", "language": ["spa"], "cover_i": 222 }
            ]
          }
        },
        {
          "key": "/works/OL2W",
          "title": "Pride &amp; Prejudice",
          "author_name": ["Jane  Austen"],
          "subject": ["Fiction, Romance, Historical, Regency"],
          "cover_i": -1,
          "editions": {
            "docs": [
              { "key": "/books/OL8M", "title": "Pride and Prejudice", "language": ["eng"] }
            ]
          }
        },
        {
          "key": "/works/OL3W",
          "title": "   ",
          "author_name": []
        }
      ]
    }
    """#

    private func decodeBooks(_ json: String) throws -> [Book] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(OpenLibrarySearchResponse.self, from: Data(json.utf8))
        return response.docs.compactMap { $0.toBook() }
    }

    // MARK: - Título, portada y edición

    @Test func usaTituloYPortadaDeLaEdicionEnEspanol() throws {
        let books = try decodeBooks(searchJSON)
        let castillo = try #require(books.first)

        #expect(castillo.id == "/works/OL1W")
        #expect(castillo.title == "El castillo")
        #expect(castillo.coverID == 222)
        #expect(castillo.editionKey == "/books/OL9M")
        #expect(castillo.year == 1926)
    }

    @Test func conservaElTituloOriginalSiNoHayEdicionEnEspanol() throws {
        let books = try decodeBooks(searchJSON)
        let orgullo = books[1]

        // Sin edición en español no se inventa una traducción del título.
        #expect(orgullo.title == "Pride & Prejudice")
        #expect(orgullo.coverID == nil)
        #expect(orgullo.editionKey == "/books/OL8M")
    }

    @Test func descartaDocumentosSinTitulo() throws {
        let books = try decodeBooks(searchJSON)
        #expect(books.count == 2)
    }

    @Test func limpiaAutoresSinTraducirlosNiDuplicarlos() throws {
        let books = try decodeBooks(searchJSON)
        #expect(books[0].author == "Franz Kafka")
        #expect(books[1].author == "Jane Austen")
    }

    @Test func traduceGenerosConocidos() throws {
        let books = try decodeBooks(searchJSON)
        #expect(books[0].genre == "Ficción")
        #expect(books[1].genre == "Romance")
    }

    // MARK: - Géneros

    @Test(arguments: [
        (["great_books_of_the_western_world", "Poetry"], "Poesía"),
        (["Fiction", "Bureaucracy"], "Ficción"),
        (["Science Fiction & Fantasy"], "Ciencia ficción"),
        (["Children's fiction"], "Infantil y juvenil"),
        (["Ciencia-ficción"], "Ciencia ficción"),
        (["Mythology, greek"], "Mitología"),
        (["Novela"], "Novela")
    ])
    func mapeaTemasAGeneroEnEspanol(temas: [String], esperado: String) {
        #expect(SubjectGenreMapper.spanishGenre(from: temas) == esperado)
    }

    // Casos reales: temas de no ficción o de público no deben definir el género de una novela.
    @Test(arguments: [
        // Ana Karenina: "Drama" se refiere a adaptaciones, no a teatro.
        (["Fiction", "Adultery", "Russian literature", "Drama"], "Ficción"),
        // Historia de dos ciudades: "Historia" es el tema y "Children's fiction" una edición juvenil.
        (["British", "Children's fiction", "Fiction", "classics", "Historia"], "Ficción"),
        // En no ficción, el tema sí es el género.
        (["Philosophy", "Nonfiction", "Classics"], "Filosofía"),
        // Formato con barra: "FICTION / Psychological".
        (["Fiction", "FICTION / Psychological"], "Novela psicológica")
    ])
    func priorizaElGeneroLiterario(temas: [String], esperado: String) {
        #expect(SubjectGenreMapper.spanishGenre(from: temas) == esperado)
    }

    @Test func sinTemasConocidosNoHayGenero() {
        #expect(SubjectGenreMapper.spanishGenre(from: ["Bureaucracy", "Castles"]) == nil)
        #expect(SubjectGenreMapper.spanishGenre(from: []) == nil)
    }

    // MARK: - Portadas

    @Test func construyeLaURLDeLaPortada() {
        let url = OpenLibraryCovers.url(coverID: 5784739, size: .medium)
        #expect(url?.absoluteString == "https://covers.openlibrary.org/b/id/5784739-M.jpg?default=false")
    }

    @Test(arguments: [nil, 0, -1] as [Int?])
    func sinPortadaValidaNoHayURL(coverID: Int?) {
        #expect(OpenLibraryCovers.url(coverID: coverID, size: .large) == nil)
    }

    @Test func elLibroEntregaLaPortadaGrandeParaElDetalle() {
        let book = Book(id: "/works/OL1W", title: "El castillo", author: "Franz Kafka", coverID: 222)
        #expect(book.coverURL(size: .large)?.absoluteString.hasSuffix("/222-L.jpg?default=false") == true)
    }

    // MARK: - Petición de búsqueda

    @Test func laBusquedaPideEdicionesEnEspanolYPortadas() throws {
        let request = try OpenLibraryService().makeRequest(query: "subject:classics")
        let url = try #require(request.url)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func value(_ name: String) -> String? { items.first { $0.name == name }?.value }

        #expect(value("q") == "subject:classics language:spa")
        #expect(value("lang") == "es")
        #expect(value("limit") == "20")
        #expect(value("fields")?.contains("cover_i") == true)
        #expect(value("fields")?.contains("editions.language") == true)
        #expect(request.value(forHTTPHeaderField: "User-Agent")?.hasPrefix("BYbooKS") == true)
    }

    // MARK: - Registros de obra y edición

    @Test func decodificaLaDescripcionComoObjetoOComoTexto() throws {
        let decoder = JSONDecoder()

        let comoObjeto = try decoder.decode(
            OpenLibraryRecord.self,
            from: Data(#"{"description": {"type": "/type/text", "value": "Hola &amp; adiós"}}"#.utf8)
        )
        let comoTexto = try decoder.decode(
            OpenLibraryRecord.self,
            from: Data(#"{"description": "Texto *simple*"}"#.utf8)
        )
        let sinDescripcion = try decoder.decode(
            OpenLibraryRecord.self,
            from: Data(#"{"title": "Sin descripción"}"#.utf8)
        )

        #expect(comoObjeto.cleanedDescription == "Hola & adiós")
        #expect(comoTexto.cleanedDescription == "Texto simple")
        #expect(sinDescripcion.cleanedDescription == nil)
    }

    @Test(arguments: [
        ("/works/OL1W", true),
        ("/books/OL9M", true),
        ("sample-odisea", false),
        ("/works/../authors", false),
        ("/authors/OL1A", false)
    ])
    func soloSeConsultanRutasDeObraOEdicion(ruta: String, valida: Bool) {
        #expect(OpenLibraryService.isRecordPath(ruta) == valida)
    }
}
