import Foundation

// Permite sustituir URLSession en las pruebas.
protocol HTTPClient {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPClient {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request)
    }
}

// Contrato de consulta de libros.
protocol BookServicing {
    func fetchBooks(query: String) async throws -> [Book]
}

// Contrato de consulta de la descripción de un libro.
// Está separado de BookServicing para que los servicios falsos existentes no tengan que cambiar.
protocol BookDescriptionServicing {
    func fetchDescription(for book: Book) async throws -> BookDescription
}

// Servicio REST de Open Library (https://openlibrary.org/developers/api).
// No necesita API Key.
struct OpenLibraryService: BookServicing, BookDescriptionServicing {

    static let baseURL = "https://openlibrary.org"

    static let searchEndpoint =
    "https://openlibrary.org/search.json"

    // Campos que se piden a la búsqueda. `editions.*` devuelve la mejor edición de cada obra
    // según el parámetro `lang`; `cover_i` es el identificador de la portada.
    static let fields = [
        "key", "title", "author_name", "first_publish_year", "subject", "cover_i",
        "editions", "editions.key", "editions.title", "editions.language", "editions.cover_i"
    ].joined(separator: ",")

    // Código MARC que usa Open Library para el español (filtro de la búsqueda).
    static let spanishLanguageCode = "spa"
    // Código ISO 639-1 del parámetro `lang` (prioriza la edición en español de cada obra).
    static let interfaceLanguage = "es"

    static let userAgent = "BYbooKS/1.0 (proyecto educativo)"

    private let client: any HTTPClient
    private let limit: Int

    init(
        client: any HTTPClient = URLSession.shared,
        limit: Int = 20
    ) {
        self.client = client
        self.limit = limit
    }

    // MARK: - Búsqueda

    func makeRequest(query: String) throws -> URLRequest {
        guard var components = URLComponents(
            string: Self.searchEndpoint
        ) else {
            throw BookServiceError.invalidURL
        }

        // Solo obras con al menos una edición en español.
        let spanishQuery = "\(query) language:\(Self.spanishLanguageCode)"

        components.queryItems = [
            URLQueryItem(name: "q", value: spanishQuery),
            URLQueryItem(name: "fields", value: Self.fields),
            URLQueryItem(name: "lang", value: Self.interfaceLanguage),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components.url else {
            throw BookServiceError.invalidURL
        }

        return makeGETRequest(url: url)
    }

    func fetchBooks(query: String) async throws -> [Book] {
        // 1. Construir petición.
        let request = try makeRequest(query: query)

        // 2 a 4. Descargar, validar la respuesta HTTP y decodificar el JSON.
        let result = try await perform(request, decoding: OpenLibrarySearchResponse.self)

        // 5. Mapear JSON al modelo de la aplicación (con el texto ya limpio).
        return result.docs.compactMap { $0.toBook() }
    }

    // MARK: - Descripción

    // Petición del registro de una obra ("/works/OL...W") o edición ("/books/OL...M").
    func makeRecordRequest(path: String) throws -> URLRequest {
        guard Self.isRecordPath(path),
              let url = URL(string: "\(Self.baseURL)\(path).json") else {
            throw BookServiceError.invalidURL
        }
        return makeGETRequest(url: url)
    }

    static func isRecordPath(_ path: String) -> Bool {
        let pattern = "^/(works|books)/OL[0-9]+[WM]$"
        return path.range(of: pattern, options: .regularExpression) != nil
    }

    // La búsqueda no incluye descripciones: se consultan aparte.
    // Primero la edición que se muestra (suele estar en español) y, solo si no tiene
    // un texto en español, la obra. La elección final la hace BookDescription.select.
    func fetchDescription(for book: Book) async throws -> BookDescription {
        var editionText: String?

        if let editionKey = book.editionKey, Self.isRecordPath(editionKey) {
            editionText = try await fetchRecordDescription(path: editionKey)

            let fromEdition = BookDescription.select(editionText: editionText, workText: nil)
            if case .spanish = fromEdition {
                return fromEdition
            }
        }

        var workText: String?
        if Self.isRecordPath(book.id) {
            workText = try await fetchRecordDescription(path: book.id)
        }

        return BookDescription.select(editionText: editionText, workText: workText)
    }

    // Devuelve la descripción limpia del registro, o nil si no tiene o si el registro no existe (404).
    private func fetchRecordDescription(path: String) async throws -> String? {
        let request = try makeRecordRequest(path: path)

        do {
            let record = try await perform(request, decoding: OpenLibraryRecord.self)
            return record.cleanedDescription
        } catch BookServiceError.httpStatus(404) {
            return nil
        }
    }

    // MARK: - Pasos comunes

    private func makeGETRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )
        // Open Library pide identificar las aplicaciones que usan su API.
        request.setValue(
            Self.userAgent,
            forHTTPHeaderField: "User-Agent"
        )
        return request
    }

    private func perform<Response: Decodable>(
        _ request: URLRequest,
        decoding type: Response.Type
    ) async throws -> Response {

        // Descargar datos reales.
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await client.send(request)

        } catch is CancellationError {
            throw CancellationError()

        } catch let error as URLError {
            if error.code == .cancelled {
                throw CancellationError()
            }
            throw BookServiceError.connectivity

        } catch {
            throw BookServiceError.unknown
        }

        try Task.checkCancellation()

        // Validar respuesta HTTP.
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BookServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw BookServiceError.httpStatus(
                httpResponse.statusCode
            )
        }

        // Decodificar JSON. JSONDecoder interpreta el texto como UTF-8.
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw BookServiceError.decoding
        }
    }
}
