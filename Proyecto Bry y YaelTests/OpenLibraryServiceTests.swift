import Foundation
import XCTest
@testable import Proyecto_Bry_y_Yael

private struct MockHTTPClient: HTTPClient {
    let result: Result<(Data, URLResponse), Error>

    func send(
    _ request: URLRequest
    ) async throws -> (Data, URLResponse) {
        try result.get()
    }
}

private struct FailingHTTPClient: HTTPClient {
    func send(
    _ request: URLRequest
    ) async throws -> (Data, URLResponse) {
        throw URLError(.notConnectedToInternet)
    }
}

private struct MockBookService: BookServicing {
    let result: Result<[Book], Error>

    func fetchBooks(query: String) async throws -> [Book] {
        try result.get()
    }
}

// Falla la primera vez y funciona la segunda: sirve para probar el botón Reintentar.
private final class FlakyBookService: BookServicing {
    private var calls = 0
    let books: [Book]

    init(books: [Book]) {
        self.books = books
    }

    func fetchBooks(query: String) async throws -> [Book] {
        calls += 1
        if calls == 1 {
            throw BookServiceError.connectivity
        }
        return books
    }
}

@MainActor
final class OpenLibraryServiceTests: XCTestCase {

    private let sampleJSON = """
                             {
                                 "docs": [
                                     {
                                         "key": "/works/OL1W",
                                         "title": "Libro de prueba",
                                         "author_name": ["Autora de prueba"],
                                         "first_publish_year": 1900,
                                         "subject": ["Novela"]
                                     },
                                     {
                                         "key": "/works/OL2W",
                                         "title": "Libro sin datos opcionales"
                                     }
                                 ]
                             }
                             """

    private func makeService(
    json: String,
    status: Int = 200
    ) -> OpenLibraryService {

        let url = URL(
            string: "https://openlibrary.org/search.json"
        )!

        let response: URLResponse = HTTPURLResponse(
            url: url,
            statusCode: status,
            httpVersion: nil,
            headerFields: nil
        )!

        let client = MockHTTPClient(
            result: .success((
            Data(json.utf8),
            response
            ))
        )

        return OpenLibraryService(client: client)
    }

    // Comprueba el mapeo de valores JSON.
    func testDecodificaYMapeaLibros() async throws {
        let service = makeService(json: sampleJSON)

        let books = try await service.fetchBooks(
            query: "subject:classics"
        )

        XCTAssertEqual(books.count, 2)
        XCTAssertEqual(books[0].id, "/works/OL1W")
        XCTAssertEqual(books[0].title, "Libro de prueba")
        XCTAssertEqual(books[0].author, "Autora de prueba")
        XCTAssertEqual(books[0].year, 1900)
        XCTAssertEqual(books[0].genre, "Novela")
    }

    // Comprueba campos opcionales ausentes.
    func testCamposFaltantes() async throws {
        let service = makeService(json: sampleJSON)

        let books = try await service.fetchBooks(
            query: "subject:classics"
        )

        XCTAssertEqual(
            books[1].author,
            "Autor desconocido"
        )
        XCTAssertNil(books[1].year)
        XCTAssertNil(books[1].genre)
    }

    // Una respuesta vacía no es un error HTTP.
    func testRespuestaVacia() async throws {
        let service = makeService(
            json: #"{"docs":[]}"#
        )

        let books = try await service.fetchBooks(
            query: "subject:classics"
        )

        XCTAssertTrue(books.isEmpty)
    }

    // Debe rechazar errores HTTP.
    func testErrorHTTP() async {
        let service = makeService(
            json: "{}",
            status: 503
        )

        do {
            _ = try await service.fetchBooks(
                query: "subject:classics"
            )
            XCTFail("Se esperaba error HTTP")
        } catch {
            XCTAssertEqual(
                error as? BookServiceError,
                .httpStatus(503)
            )
        }
    }

    // Debe detectar respuestas JSON inválidas.
    func testErrorDecodificacion() async {
        let service = makeService(
            json: #"{"docs":"incorrecto"}"#
        )

        do {
            _ = try await service.fetchBooks(
                query: "subject:classics"
            )
            XCTFail("Se esperaba error de decodificación")
        } catch let error as BookServiceError {
            switch error {
            case .decoding:
                break
            default:
                XCTFail("Tipo de error incorrecto")
            }
        } catch {
            XCTFail("Se recibió un error inesperado")
        }
    }

    // Simula una pérdida de conexión.
    func testErrorDeConectividad() async {
        let service = OpenLibraryService(
            client: FailingHTTPClient()
        )

        do {
            _ = try await service.fetchBooks(
                query: "subject:classics"
            )
            XCTFail("Se esperaba error de conexión")
        } catch {
            XCTAssertEqual(
                error as? BookServiceError,
                .connectivity
            )
        }
    }

    // El ViewModel debe actualizar el BookStore.
    func testViewModelRecibeLibros() async {
        let book = Book(
            id: "/works/OL1W",
            title: "Libro de prueba",
            author: "Autora",
            year: 1900,
            genre: "Novela",
            description: ""
        )

        let store = BookStore()

        let viewModel = BookListViewModel(
            store: store,
            service: MockBookService(
                result: .success([book])
            )
        )

        await viewModel.loadBooks()

        XCTAssertEqual(
            store.catalogState,
            .content([book])
        )
        XCTAssertEqual(viewModel.filteredBooks.count, 1)
    }

    // No deben confundirse datos vacíos con errores.
    func testViewModelSinResultados() async {
        let store = BookStore()

        let viewModel = BookListViewModel(
            store: store,
            service: MockBookService(
                result: .success([])
            )
        )

        await viewModel.loadBooks()

        XCTAssertEqual(store.catalogState, .empty)
        XCTAssertFalse(viewModel.noResults)
    }

    // Los favoritos deben sobrevivir a un error de red.
    func testFavoritosDisponiblesSinConexion() {
        let store = BookStore()

        let book = Book(
            id: "/works/OL1W",
            title: "Libro guardado",
            author: "Autora",
            year: 1900,
            genre: "Novela",
            description: ""
        )

        store.toggleFavorite(book)

        store.catalogState = .error(
            .connectivity
        )

        XCTAssertTrue(store.books.isEmpty)
        XCTAssertEqual(store.favorites.count, 1)
        XCTAssertEqual(
            store.favorites[0].title,
            "Libro guardado"
        )
    }

    // El ViewModel debe representar el error del servicio en el estado.
    func testViewModelRepresentaElError() async {
        let store = BookStore()

        let viewModel = BookListViewModel(
            store: store,
            service: MockBookService(
                result: .failure(BookServiceError.httpStatus(500))
            )
        )

        await viewModel.loadBooks()

        XCTAssertEqual(store.catalogState, .error(.httpStatus(500)))
        XCTAssertTrue(store.books.isEmpty)
    }

    // Reintentar después de un error debe cargar los libros.
    func testReintentarDespuesDeUnError() async {
        let book = Book(
            id: "/works/OL1W",
            title: "Libro de prueba",
            author: "Autora",
            year: 1900,
            genre: "Novela",
            description: ""
        )

        let store = BookStore()

        let viewModel = BookListViewModel(
            store: store,
            service: FlakyBookService(books: [book])
        )

        await viewModel.loadBooks()
        XCTAssertEqual(
            store.catalogState,
            .error(.connectivity)
        )

        await viewModel.retry()
        XCTAssertEqual(store.catalogState, .content([book]))
    }

    // Solo se descarga si todavía no se había pedido el catálogo.
    func testLoadIfNeededNoRepiteLaDescarga() async {
        let store = BookStore()
        store.catalogState = .empty

        let viewModel = BookListViewModel(
            store: store,
            service: MockBookService(result: .success([]))
        )

        await viewModel.loadIfNeeded()

        XCTAssertEqual(store.catalogState, .empty)
    }
}
