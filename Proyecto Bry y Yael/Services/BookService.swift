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

struct OpenLibraryService: BookServicing {

    static let searchEndpoint =
    "https://openlibrary.org/search.json"

    static let fields =
    "key,title,author_name,first_publish_year,subject"

    private let client: any HTTPClient
    private let limit: Int

    init(
    client: any HTTPClient = URLSession.shared,
    limit: Int = 20
    ) {
        self.client = client
        self.limit = limit
    }

    func makeRequest(query: String) throws -> URLRequest {
        guard var components = URLComponents(
            string: Self.searchEndpoint
        ) else {
            throw BookServiceError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "fields", value: Self.fields),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components.url else {
            throw BookServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )
        request.setValue(
            "AJBooks/1.0 (proyecto educativo)",
            forHTTPHeaderField: "User-Agent"
        )

        return request
    }

    func fetchBooks(query: String) async throws -> [Book] {

        // 1. Construir petición.
        let request = try makeRequest(query: query)

        // 2. Descargar datos reales.
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

        // 3. Validar respuesta HTTP.
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BookServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw BookServiceError.httpStatus(
                httpResponse.statusCode
            )
        }

        // 4. Decodificar JSON.
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let result = try decoder.decode(
                OpenLibrarySearchResponse.self,
                from: data
            )

            // 5. Mapear JSON al modelo de la aplicación.
            let books = result.docs.map { $0.toBook() }

            print("Open Library: \(books.count) libros recibidos")

            return books

        } catch {
            throw BookServiceError.decoding
        }
    }
}
