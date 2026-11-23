import Testing
@testable import Proyecto_Bry_y_Yael

// Servicio falso que registra cada consulta para comprobar cuándo se llama a Open Library.
@MainActor
private final class RecordingBookService: BookServicing {
    var result: Result<[Book], Error>
    private(set) var queries: [String] = []

    init(result: Result<[Book], Error>) {
        self.result = result
    }

    func fetchBooks(query: String) async throws -> [Book] {
        queries.append(query)
        return try result.get()
    }
}

// Pruebas de la búsqueda automática: al escribir se consulta Open Library
// sin tener que presionar "Buscar".
@MainActor
struct BusquedaAutomaticaTests {

    private let remoto = Book(
        id: "/works/OL9W",
        title: "Thus Spoke Zarathustra",
        author: "Friedrich Nietzsche",
        description: ""
    )

    // Sin pausa para que las pruebas no esperen.
    private func makeViewModel(_ service: RecordingBookService) -> BookListViewModel {
        BookListViewModel(store: makeSeededStore(), service: service, searchDelay: .zero)
    }

    @Test func alEscribirSeConsultaOpenLibraryAutomaticamente() async {
        let service = RecordingBookService(result: .success([remoto]))
        let viewModel = makeViewModel(service)

        viewModel.searchText = "Thu"
        await viewModel.searchAfterTyping()

        #expect(service.queries == ["Thu"])
        #expect(viewModel.searchState == .content([remoto]))
        #expect(viewModel.searchResults == [remoto])
    }

    @Test func losLibrosLocalesAparecenPrimeroYSinRepetirse() async {
        let odiseaLocal = makeSeededStore().books[0]
        let service = RecordingBookService(result: .success([odiseaLocal, remoto]))
        let viewModel = makeViewModel(service)

        viewModel.searchText = "odisea"
        await viewModel.searchAfterTyping()

        #expect(viewModel.searchResults.map(\.id) == [odiseaLocal.id, remoto.id])
    }

    @Test func mientrasSeBuscaSeVenLasCoincidenciasLocales() {
        let viewModel = makeViewModel(RecordingBookService(result: .success([])))

        viewModel.searchText = "páramo"

        #expect(viewModel.hasSearchText)
        #expect(viewModel.searchResults.map(\.title) == ["Pedro Páramo"])
    }

    @Test func textoVacioRegresaAlCatalogoSinConsultar() async {
        let service = RecordingBookService(result: .success([remoto]))
        let viewModel = makeViewModel(service)

        viewModel.searchText = "   "
        await viewModel.searchAfterTyping()

        #expect(service.queries.isEmpty)
        #expect(viewModel.hasSearchText == false)
        #expect(viewModel.searchState == .idle)
    }

    @Test func alRegresarDelDetalleNoSeRepiteLaBusqueda() async {
        let service = RecordingBookService(result: .success([remoto]))
        let viewModel = makeViewModel(service)
        viewModel.searchText = "Thu"

        await viewModel.searchAfterTyping()
        // Al volver a la pantalla, .task(id:) se ejecuta otra vez con el mismo texto.
        await viewModel.searchAfterTyping()

        #expect(service.queries.count == 1)
    }

    @Test func siElUsuarioSigueEscribiendoNoSeConsultaElTextoAnterior() async {
        let service = RecordingBookService(result: .success([remoto]))
        let viewModel = BookListViewModel(
            store: makeSeededStore(),
            service: service,
            searchDelay: .seconds(30)
        )
        viewModel.searchText = "Th"

        // SwiftUI cancela la tarea cuando cambia el texto; aquí se simula esa cancelación.
        let tarea = Task { await viewModel.searchAfterTyping() }
        tarea.cancel()
        await tarea.value

        #expect(service.queries.isEmpty)
    }

    @Test func sinCoincidenciasSeMuestraUnMensajeClaro() async {
        let viewModel = makeViewModel(RecordingBookService(result: .success([])))

        viewModel.searchText = "zzzz"
        await viewModel.searchAfterTyping()

        #expect(viewModel.searchState == .empty)
        #expect(viewModel.searchResults.isEmpty)
        #expect(viewModel.noMatchesMessage.contains("“zzzz”"))
    }

    @Test func sinConexionLaBusquedaMuestraElError() async {
        let service = RecordingBookService(result: .failure(BookServiceError.connectivity))
        let viewModel = makeViewModel(service)

        viewModel.searchText = "Thu"
        await viewModel.searchAfterTyping()

        #expect(viewModel.searchState == .error(.connectivity))
    }

    @Test func presionarBuscarConsultaDeInmediato() async {
        let service = RecordingBookService(result: .success([remoto]))
        let viewModel = BookListViewModel(
            store: makeSeededStore(),
            service: service,
            searchDelay: .seconds(30)
        )

        viewModel.searchText = "Thu"
        await viewModel.search()

        #expect(service.queries == ["Thu"])
        #expect(viewModel.searchState == .content([remoto]))
    }
}
