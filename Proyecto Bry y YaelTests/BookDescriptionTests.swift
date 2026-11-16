import Foundation
import Testing
@testable import Proyecto_Bry_y_Yael

// Textos de prueba escritos para estas pruebas (no son sinopsis reales).
private let textoEnEspanol = "Una novela sobre la memoria y el exilio, contada por un narrador que vuelve a su pueblo después de muchos años."
private let textoEnIngles = "A novel about memory and exile, told by a narrator who returns to his hometown after many years away from it."

// Cliente HTTP falso que responde según la ruta pedida y registra las rutas consultadas.
@MainActor
private final class RoutingHTTPClient: HTTPClient {
    var routes: [String: (status: Int, body: String)] = [:]
    var failsWithoutConnection = false
    private(set) var requestedPaths: [String] = []

    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        let url = try #require(request.url)
        requestedPaths.append(url.path)

        if failsWithoutConnection {
            throw URLError(.notConnectedToInternet)
        }

        let route = routes[url.path] ?? (404, "{}")
        let response = try #require(
            HTTPURLResponse(url: url, statusCode: route.status, httpVersion: nil, headerFields: nil)
        )
        return (Data(route.body.utf8), response)
    }
}

// Servicio de descripciones falso para probar BookStore sin red.
@MainActor
private final class StubDescriptionService: BookDescriptionServicing {
    var result: Result<BookDescription, Error>
    private(set) var calls = 0

    init(result: Result<BookDescription, Error>) {
        self.result = result
    }

    func fetchDescription(for book: Book) async throws -> BookDescription {
        calls += 1
        return try result.get()
    }
}

private func descriptionJSON(_ text: String) -> String {
    let data = try? JSONSerialization.data(withJSONObject: ["description": ["type": "/type/text", "value": text]])
    return data.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
}

@MainActor
struct BookDescriptionTests {

    private let castillo = Book(
        id: "/works/OL1W",
        title: "El castillo",
        author: "Franz Kafka",
        editionKey: "/books/OL9M"
    )

    // Detector simulado: hace que las pruebas de la regla no dependan del idioma real.
    private func fakeDetector(_ text: String) -> String? {
        text.hasPrefix("ES:") ? "es" : "en"
    }

    private func repeated(_ prefix: String) -> String {
        prefix + String(repeating: " texto", count: 15)
    }

    // MARK: - Regla de selección

    @Test func prefiereLaDescripcionEnEspanolDeLaEdicion() {
        let result = BookDescription.select(
            editionText: repeated("ES: edición"),
            workText: repeated("ES: obra"),
            languageOf: fakeDetector
        )
        #expect(result == .spanish(repeated("ES: edición")))
    }

    @Test func usaLaObraSiLaEdicionNoEstaEnEspanol() {
        let result = BookDescription.select(
            editionText: repeated("EN: edition"),
            workText: repeated("ES: obra"),
            languageOf: fakeDetector
        )
        #expect(result == .spanish(repeated("ES: obra")))
    }

    @Test func soloEnOtroIdiomaSeConservaParaTraducirAPeticion() {
        let result = BookDescription.select(
            editionText: nil,
            workText: repeated("EN: work"),
            languageOf: fakeDetector
        )
        #expect(result == .otherLanguage(text: repeated("EN: work"), languageCode: "en"))
    }

    @Test func ignoraCreditosEditorialesCortos() {
        // Caso real de Open Library: la "descripción" de la edición es solo un crédito.
        let result = BookDescription.select(
            editionText: "ES: Edición de Luis Acosta",
            workText: nil,
            languageOf: fakeDetector
        )
        #expect(result == .unavailable)
    }

    @Test func sinTextosNoHayDescripcion() {
        #expect(BookDescription.select(editionText: nil, workText: nil, languageOf: fakeDetector) == .unavailable)
    }

    // MARK: - Detector de idioma

    @Test func detectaEspanolEIngles() {
        #expect(LanguageDetector.languageCode(of: textoEnEspanol) == "es")
        #expect(LanguageDetector.languageCode(of: textoEnIngles) == "en")
        #expect(LanguageDetector.languageCode(of: "12345 !!!") == nil)
    }

    @Test func laHeuristicaDeRespaldoTambienDistingueIdiomas() {
        #expect(LanguageDetector.heuristicLanguageCode(of: textoEnEspanol) == "es")
        #expect(LanguageDetector.heuristicLanguageCode(of: textoEnIngles) == "en")
    }

    @Test(arguments: [
        ("en", "inglés"),
        ("en-US", "inglés"),
        ("fr", "francés")
    ])
    func nombraElIdiomaEnEspanol(codigo: String, nombre: String) {
        #expect(LanguageDetector.spanishName(forLanguageCode: codigo) == nombre)
    }

    @Test func idiomaDesconocidoSeNombraComoOtroIdioma() {
        #expect(LanguageDetector.spanishName(forLanguageCode: nil) == "otro idioma")
    }

    // MARK: - Servicio (edición -> obra)

    @Test func siLaEdicionTieneTextoEnEspanolNoConsultaLaObra() async throws {
        let client = RoutingHTTPClient()
        client.routes["/books/OL9M.json"] = (200, descriptionJSON(textoEnEspanol))
        client.routes["/works/OL1W.json"] = (200, descriptionJSON(textoEnIngles))
        let service = OpenLibraryService(client: client)

        let result = try await service.fetchDescription(for: castillo)

        #expect(result == .spanish(textoEnEspanol))
        #expect(client.requestedPaths == ["/books/OL9M.json"])
    }

    @Test func siLaEdicionNoExisteUsaLaObra() async throws {
        let client = RoutingHTTPClient()
        client.routes["/works/OL1W.json"] = (200, descriptionJSON(textoEnIngles))
        let service = OpenLibraryService(client: client)

        let result = try await service.fetchDescription(for: castillo)

        #expect(result == .otherLanguage(text: textoEnIngles, languageCode: "en"))
        #expect(client.requestedPaths == ["/books/OL9M.json", "/works/OL1W.json"])
    }

    @Test func limpiaLaDescripcionAntesDeEntregarla() async throws {
        let client = RoutingHTTPClient()
        client.routes["/works/OL1W.json"] = (200, descriptionJSON("***\(textoEnEspanol)***\r\n\r\n  [1]: https://example.com"))
        let service = OpenLibraryService(client: client)
        let sinEdicion = Book(id: "/works/OL1W", title: "El castillo", author: "Franz Kafka")

        let result = try await service.fetchDescription(for: sinEdicion)

        #expect(result == .spanish(textoEnEspanol))
    }

    @Test func sinConexionLanzaErrorDeConectividad() async {
        let client = RoutingHTTPClient()
        client.failsWithoutConnection = true
        let service = OpenLibraryService(client: client)

        await #expect(throws: BookServiceError.connectivity) {
            try await service.fetchDescription(for: castillo)
        }
    }

    @Test func librosDeEjemploNoConsultanLaRed() async throws {
        let client = RoutingHTTPClient()
        let service = OpenLibraryService(client: client)
        let ejemplo = Book(id: "sample-odisea", title: "La Odisea", author: "Homero")

        let result = try await service.fetchDescription(for: ejemplo)

        #expect(result == .unavailable)
        #expect(client.requestedPaths.isEmpty)
    }

    // MARK: - BookStore (fuente única de verdad)

    @Test func elStoreGuardaLaDescripcionCargada() async {
        let service = StubDescriptionService(result: .success(.spanish(textoEnEspanol)))
        let store = BookStore(descriptionService: service)

        #expect(store.descriptionState(for: castillo) == .idle)
        await store.loadDescription(for: castillo)

        #expect(store.descriptionState(for: castillo) == .loaded(.spanish(textoEnEspanol)))
    }

    @Test func noRepiteLaDescargaDeUnaDescripcionYaPedida() async {
        let service = StubDescriptionService(result: .success(.unavailable))
        let store = BookStore(descriptionService: service)

        store.requestDescription(for: castillo)
        await store.loadDescription(for: castillo)
        await store.loadDescription(for: castillo)

        #expect(service.calls == 1)
    }

    @Test func unErrorQuedaComoFallidoYSePuedeReintentar() async {
        let service = StubDescriptionService(result: .failure(BookServiceError.connectivity))
        let store = BookStore(descriptionService: service)

        await store.loadDescription(for: castillo)
        #expect(store.descriptionState(for: castillo) == .failed)

        service.result = .success(.spanish(textoEnEspanol))
        await store.reloadDescription(for: castillo)

        #expect(store.descriptionState(for: castillo) == .loaded(.spanish(textoEnEspanol)))
        #expect(service.calls == 2)
    }

    @Test func unaDescripcionPrecargadaNoUsaElServicio() async {
        let service = StubDescriptionService(result: .success(.unavailable))
        let store = BookStore(descriptionService: service)
        let conTexto = Book(id: "local-1", title: "Libro", author: "Autora", description: "Descripción &amp; detalle.")

        await store.loadDescription(for: conTexto)

        #expect(store.descriptionState(for: conTexto) == .loaded(.spanish("Descripción & detalle.")))
        #expect(service.calls == 0)
    }

    // MARK: - Presentación (lo que ven la tarjeta y el detalle)

    @Test func laTarjetaMuestraUnResumenEnUnaSolaSecuencia() {
        let state = DescriptionState.loaded(.spanish("Primer párrafo.\n\nSegundo párrafo."))
        #expect(state.preview == .summary("Primer párrafo. Segundo párrafo."))
    }

    @Test(arguments: [
        (.idle, .loading),
        (.loading, .loading),
        (.loaded(.otherLanguage(text: "x", languageCode: "en")), .notice("Descripción disponible solo en inglés")),
        (.loaded(.unavailable), .notice("Descripción no disponible")),
        (.failed, .notice("No se pudo cargar la descripción"))
    ] as [(DescriptionState, DescriptionPreview)])
    func laTarjetaExplicaPorQueNoHayResumen(estado: DescriptionState, esperado: DescriptionPreview) {
        #expect(estado.preview == esperado)
    }

    @Test func elDetalleOfreceElTextoOriginalSoloParaTraducir() {
        let state = DescriptionState.loaded(.otherLanguage(text: textoEnIngles, languageCode: "en"))
        #expect(state.detailContent == .onlyInOtherLanguage(languageName: "inglés", original: textoEnIngles))
    }

    @Test func elDetalleExplicaCuandoNoHayDescripcion() async {
        let service = StubDescriptionService(result: .success(.unavailable))
        let store = BookStore(descriptionService: service)
        let viewModel = BookDetailViewModel(book: castillo, store: store)

        await viewModel.loadDescription()

        #expect(viewModel.descriptionContent == .unavailable)
        #expect(viewModel.descriptionText == "Descripción no disponible.")
    }

    // MARK: - Favoritos con portada

    @Test func elFavoritoConservaPortadaYEdicion() {
        let book = Book(id: "/works/OL1W", title: "El castillo", author: "Franz Kafka", coverID: 222, editionKey: "/books/OL9M")

        let restored = FavoriteBook(book: book).toBook()

        #expect(restored.coverID == 222)
        #expect(restored.editionKey == "/books/OL9M")
    }

    @Test func laTarjetaPuedeGuardarYQuitarFavoritos() {
        let store = makeSeededStore()
        let viewModel = BookListViewModel(store: store)
        let book = store.books[0]

        viewModel.toggleFavorite(book)
        #expect(viewModel.isFavorite(book))
        #expect(viewModel.favoritesAccessibilityLabel == "Ver favoritos, 1 libro guardado")

        viewModel.toggleFavorite(book)
        #expect(!viewModel.isFavorite(book))
    }

    @Test func resumenDeResultadosYMensajeSinCoincidencias() {
        let viewModel = BookListViewModel(store: makeSeededStore())
        #expect(viewModel.resultsSummary == "6 libros")

        viewModel.searchText = "  zzzz "
        #expect(viewModel.resultsSummary == "0 libros")
        #expect(viewModel.noResultsMessage == "No se encontraron libros para “zzzz”")
    }
}
