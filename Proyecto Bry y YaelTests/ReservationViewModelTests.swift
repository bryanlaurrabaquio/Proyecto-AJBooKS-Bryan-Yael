import Foundation
import Testing
@testable import Proyecto_Bry_y_Yael

// Pruebas de lo que muestran las pantallas de apartados (textos, listas y mensajes),
// sin abrir la interfaz.
@MainActor
struct ReservationViewModelTests {

    // Tienda con un libro de 2 ejemplares y un perfil de encargada.
    private func makeStockViewModel(
        existence: Int = 2,
        role: UserRole = .encargada
    ) throws -> (BookStockViewModel, ReservationStore) {
        let store = makeReservationStore(clock: TestClock())
        let libro = makeBook()
        if existence > 0 {
            try store.setExistence(for: libro, to: existence, by: .encargada)
        }
        let viewModel = BookStockViewModel(
            book: libro,
            reservations: store,
            profile: ProfileStore(role: role)
        )
        return (viewModel, store)
    }

    // MARK: - Detalle del libro

    @Test func sinInventarioElDetalleLoExplicaYNoDejaApartar() throws {
        let (viewModel, _) = try makeStockViewModel(existence: 0)

        #expect(viewModel.availabilityText == "Este libro todavía no está en el inventario del local.")
        #expect(viewModel.breakdownText == nil)
        #expect(viewModel.canReserve == false)
    }

    @Test func conInventarioElDetalleMuestraLosDisponibles() throws {
        let (viewModel, _) = try makeStockViewModel(existence: 3)

        #expect(viewModel.availabilityText == "Disponibles: 3")
        #expect(viewModel.breakdownText == "Existencia física: 3 · Apartados activos: 0")
        #expect(viewModel.canReserve)
    }

    @Test func alApartarElDetalleSeActualizaYConfirmaElFolio() throws {
        let (viewModel, _) = try makeStockViewModel(existence: 2)

        let folio = viewModel.reserve(customerName: "Ana")

        #expect(folio?.folioLabel == "#001")
        #expect(viewModel.availabilityText == "Disponibles: 1")
        #expect(viewModel.breakdownText == "Existencia física: 2 · Apartados activos: 1")
        #expect(viewModel.confirmationMessage?.contains("#001") == true)
        #expect(viewModel.confirmationMessage?.contains("Ana") == true)
        #expect(viewModel.reserveErrorMessage == nil)
    }

    @Test func alApartarElUltimoEjemplarElDetalleDiceSinStock() throws {
        let (viewModel, _) = try makeStockViewModel(existence: 1)

        viewModel.reserve(customerName: "Cliente A")
        let segundo = viewModel.reserve(customerName: "Cliente B")

        #expect(segundo == nil)
        #expect(viewModel.availabilityText == "Sin stock")
        #expect(viewModel.canReserve == false)
        #expect(viewModel.reserveErrorMessage?.hasPrefix("Sin stock") == true)
        #expect(viewModel.confirmationMessage == nil)
    }

    @Test func unNombreVacioMuestraElMotivo() throws {
        let (viewModel, store) = try makeStockViewModel(existence: 2)

        let folio = viewModel.reserve(customerName: "  ")

        #expect(folio == nil)
        #expect(viewModel.reserveErrorMessage == "Escribe el nombre del cliente.")
        #expect(store.reservations.isEmpty)
    }

    @Test func laEncargadaNoPuedeBajarLaExistenciaPorDebajoDeLosApartados() throws {
        let (viewModel, _) = try makeStockViewModel(existence: 1)
        viewModel.reserve(customerName: "Ana")

        #expect(viewModel.canDecreaseExistence == false)

        viewModel.adjustExistence(by: -1)

        #expect(viewModel.existence == 1)
        #expect(viewModel.adjustErrorMessage?.contains("apartados activos") == true)
    }

    // MARK: - Folios

    @Test func losFoliosActivosYCerradosSeSeparanConLosMasRecientesPrimero() throws {
        let store = makeReservationStore(clock: TestClock())
        let libro = makeBook()
        try store.setExistence(for: libro, to: 5, by: .encargada)
        for nombre in ["Ana", "Luis", "Marta"] {
            try store.reserve(book: libro, customerName: nombre, by: .vendedor)
        }
        let viewModel = ReservationsViewModel(reservations: store, profile: ProfileStore())

        viewModel.deliver(store.reservations[0])
        viewModel.cancel(store.reservations[1])

        #expect(viewModel.activeFolios.map(\.customerName) == ["Marta"])
        #expect(viewModel.closedFolios.map(\.customerName) == ["Luis", "Ana"])
        #expect(viewModel.isEmpty == false)
    }

    @Test func sinFoliosLaListaEstaVacia() {
        let viewModel = ReservationsViewModel(
            reservations: makeReservationStore(clock: TestClock()),
            profile: ProfileStore()
        )

        #expect(viewModel.isEmpty)
        #expect(viewModel.activeFolios.isEmpty)
    }

    @Test func entregarDosVecesMuestraElMotivoEnEspanol() throws {
        let store = makeReservationStore(clock: TestClock())
        let libro = makeBook()
        try store.setExistence(for: libro, to: 2, by: .encargada)
        try store.reserve(book: libro, customerName: "Ana", by: .vendedor)
        let viewModel = ReservationsViewModel(reservations: store, profile: ProfileStore())
        let folio = store.reservations[0]

        viewModel.deliver(folio)
        viewModel.deliver(folio)

        #expect(viewModel.errorMessage == "El folio ya está entregado.")
        #expect(store.stock(for: libro.id)?.existence == 1)
    }

    @Test func refrescarMarcaLosFoliosVencidos() throws {
        let reloj = TestClock()
        let store = makeReservationStore(clock: reloj)
        let libro = makeBook()
        try store.setExistence(for: libro, to: 1, by: .encargada)
        try store.reserve(book: libro, customerName: "Ana", by: .vendedor)
        let viewModel = ReservationsViewModel(reservations: store, profile: ProfileStore())

        reloj.advance(days: ReservationPolicy.standard.expirationDays + 1)
        viewModel.refresh()

        #expect(viewModel.activeFolios.isEmpty)
        #expect(viewModel.closedFolios.first?.status == .vencido)
    }

    @Test func laLineaDeFechaDependeDelEstadoDelFolio() throws {
        let store = makeReservationStore(clock: TestClock())
        let libro = makeBook()
        try store.setExistence(for: libro, to: 3, by: .encargada)
        for nombre in ["Ana", "Luis"] {
            try store.reserve(book: libro, customerName: nombre, by: .vendedor)
        }
        let viewModel = ReservationsViewModel(reservations: store, profile: ProfileStore())
        viewModel.deliver(store.reservations[0])
        viewModel.cancel(store.reservations[1])

        #expect(viewModel.detailLine(for: store.reservations[0]).hasPrefix("Entregado el"))
        #expect(viewModel.detailLine(for: store.reservations[1]).hasPrefix("Cancelado el"))
    }

    @Test func laLineaDeFechaDeUnFolioActivoIndicaElVencimiento() throws {
        let (viewModel, store) = try makeStockViewModel(existence: 1)
        viewModel.reserve(customerName: "Ana")
        let folios = ReservationsViewModel(reservations: store, profile: ProfileStore())

        #expect(folios.detailLine(for: store.reservations[0]).hasPrefix("Vence el"))
        #expect(folios.customerLine(for: store.reservations[0]) == "Cliente: Ana · Apartó: Encargada")
    }

    // MARK: - Inventario

    @Test func elInventarioSeOrdenaPorTituloYMuestraSusExistencias() throws {
        let store = makeReservationStore(clock: TestClock())
        let odisea = makeBook(id: "/works/OL2W", title: "La Odisea")
        let quijote = makeBook(id: "/works/OL1W", title: "Don Quijote")
        try store.setExistence(for: odisea, to: 4, by: .encargada)
        try store.setExistence(for: quijote, to: 2, by: .encargada)
        try store.reserve(book: quijote, customerName: "Ana", by: .vendedor)
        let viewModel = InventoryViewModel(reservations: store, profile: ProfileStore(role: .encargada))

        #expect(viewModel.rows.map(\.item.title) == ["Don Quijote", "La Odisea"])
        #expect(viewModel.rows[0].summary == StockSummary(existence: 2, activeReservations: 1))
        #expect(viewModel.rows[1].summary.available == 4)
    }

    @Test func laEncargadaAjustaLaExistenciaDesdeElInventario() throws {
        let store = makeReservationStore(clock: TestClock())
        let libro = makeBook()
        try store.setExistence(for: libro, to: 2, by: .encargada)
        let viewModel = InventoryViewModel(reservations: store, profile: ProfileStore(role: .encargada))

        viewModel.increase(viewModel.rows[0])
        viewModel.decrease(viewModel.rows[0])
        viewModel.decrease(viewModel.rows[0])

        #expect(store.stock(for: libro.id)?.existence == 1)
        #expect(viewModel.errorMessage == nil)
    }

    @Test func elInventarioNoDejaBajarDeLosApartadosActivos() throws {
        let store = makeReservationStore(clock: TestClock())
        let libro = makeBook()
        try store.setExistence(for: libro, to: 1, by: .encargada)
        try store.reserve(book: libro, customerName: "Ana", by: .vendedor)
        let viewModel = InventoryViewModel(reservations: store, profile: ProfileStore(role: .encargada))
        let fila = viewModel.rows[0]

        #expect(viewModel.canDecrease(fila) == false)

        viewModel.decrease(fila)

        #expect(store.stock(for: libro.id)?.existence == 1)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func sinLibrosElInventarioEstaVacio() {
        let viewModel = InventoryViewModel(
            reservations: makeReservationStore(clock: TestClock()),
            profile: ProfileStore()
        )

        #expect(viewModel.isEmpty)
        #expect(viewModel.rows.isEmpty)
    }

    @Test func elInventarioConvierteUnRegistroEnUnLibroConPortada() throws {
        let store = makeReservationStore(clock: TestClock())
        try store.setExistence(for: makeBook(), to: 1, by: .encargada)

        let libro = try #require(store.inventory.first).asBook

        #expect(libro.id == "/works/OL1W")
        #expect(libro.title == "Don Quijote de la Mancha")
        #expect(libro.coverID == 123)
        #expect(libro.coverURL(size: "L")?.absoluteString == "https://covers.openlibrary.org/b/id/123-L.jpg")
    }
}
