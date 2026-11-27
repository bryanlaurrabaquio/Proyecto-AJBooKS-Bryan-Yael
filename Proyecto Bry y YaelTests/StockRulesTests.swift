import Foundation
import Testing
@testable import Proyecto_Bry_y_Yael

// Todas las combinaciones de existencia (0 a 5) y apartados (0 hasta la existencia).
private let combinacionesDeStock: [(Int, Int)] = (0...5).flatMap { existencia in
    (0...existencia).map { apartados in (existencia, apartados) }
}

// Combinaciones con al menos un apartado, para probar entregar y cancelar.
private let combinacionesConApartados: [(Int, Int)] = combinacionesDeStock.filter { $0.1 > 0 }

// Pruebas de las reglas de stock, folios y vencimiento del módulo de apartados.
// Usan almacenamiento en memoria y un reloj falso: no tocan disco ni red.
@MainActor
struct StockRulesTests {

    // MARK: - Regla 1: Disponibles = Existencia física − Apartados activos

    @Test(arguments: [
        (0, 0, 0), (1, 0, 1), (1, 1, 0), (2, 1, 1),
        (3, 1, 2), (5, 5, 0), (10, 3, 7), (10, 10, 0)
    ])
    func formulaDeDisponibles(existencia: Int, activos: Int, esperado: Int) {
        let resumen = StockSummary(existence: existencia, activeReservations: activos)

        #expect(resumen.available == esperado)
    }

    @Test(arguments: combinacionesDeStock)
    func disponiblesSiempreEsExistenciaMenosApartados(existencia: Int, apartados: Int) throws {
        let store = makeReservationStore(clock: TestClock())
        let libro = makeBook()

        try store.setExistence(for: libro, to: existencia, by: .encargada)
        for indice in 0..<apartados {
            try store.reserve(book: libro, customerName: "Cliente \(indice)", by: .vendedor)
        }

        let resumen = try #require(store.stock(for: libro.id))
        #expect(resumen.existence == existencia)
        #expect(resumen.activeReservations == apartados)
        #expect(resumen.available == existencia - apartados)
    }

    // MARK: - Búsqueda: qué stock se muestra

    @Test func unLibroSinInventarioNoMuestraStock() {
        let store = makeReservationStore(clock: TestClock())

        #expect(store.stock(for: "/works/OL1W") == nil)
        #expect(store.availability(for: makeBook()) == .notStocked)
        #expect(BookAvailability.notStocked.chipText == nil)
    }

    @Test(arguments: [
        (StockSummary(existence: 3, activeReservations: 1), BookAvailability.available(2)),
        (StockSummary(existence: 1, activeReservations: 0), BookAvailability.available(1)),
        (StockSummary(existence: 2, activeReservations: 2), BookAvailability.soldOut),
        (StockSummary(existence: 0, activeReservations: 0), BookAvailability.soldOut)
    ])
    func laDisponibilidadSeDeduceDelResumen(resumen: StockSummary, esperada: BookAvailability) {
        #expect(BookAvailability(summary: resumen) == esperada)
    }

    @Test func lasEtiquetasDeLaTarjetaEstanEnEspanol() {
        #expect(BookAvailability.available(2).chipText == "Disponibles: 2")
        #expect(BookAvailability.soldOut.chipText == "Sin stock")
        #expect(BookAvailability.soldOut.canReserve == false)
        #expect(BookAvailability.available(1).canReserve)
    }

    @Test func cadaLibroTieneSuPropioStock() throws {
        let store = makeReservationStore(clock: TestClock())
        let quijote = makeBook(id: "/works/OL1W", title: "Don Quijote")
        let odisea = makeBook(id: "/works/OL2W", title: "La Odisea")

        try store.setExistence(for: quijote, to: 2, by: .encargada)
        try store.setExistence(for: odisea, to: 5, by: .encargada)
        try store.reserve(book: quijote, customerName: "Ana", by: .vendedor)

        #expect(store.stock(for: quijote.id)?.available == 1)
        #expect(store.stock(for: odisea.id)?.available == 5)
    }

    // MARK: - Regla 2: último ejemplar

    @Test func elUltimoEjemplarSoloSeApartaUnaVez() throws {
        let store = makeReservationStore(clock: TestClock())
        let libro = makeBook()
        try store.setExistence(for: libro, to: 1, by: .encargada)

        let primero = try store.reserve(book: libro, customerName: "Cliente A", by: .vendedor)

        #expect(primero.folioLabel == "#001")
        #expect(throws: ReservationError.outOfStock) {
            try store.reserve(book: libro, customerName: "Cliente B", by: .vendedor)
        }
        #expect(store.reservations.count == 1)
        #expect(store.availability(for: libro) == .soldOut)
    }

    @Test func variasSolicitudesSimultaneasPorElUltimoEjemplarCreanUnSoloFolio() async throws {
        let store = makeReservationStore(clock: TestClock())
        try store.setExistence(for: makeBook(), to: 1, by: .encargada)

        // Diez solicitudes a la vez; todas se ejecutan en el MainActor, una tras otra.
        let exitos = await withTaskGroup(of: Bool.self) { grupo in
            for indice in 0..<10 {
                grupo.addTask { @MainActor in
                    let reserva = try? store.reserve(
                        book: makeBook(),
                        customerName: "Cliente \(indice)",
                        by: .vendedor
                    )
                    return reserva != nil
                }
            }

            var total = 0
            for await exito in grupo where exito {
                total += 1
            }
            return total
        }

        #expect(exitos == 1)
        #expect(store.reservations.count == 1)
    }

    @Test func sinExistenciaNoSePuedeApartar() throws {
        let store = makeReservationStore(clock: TestClock())
        let libro = makeBook()
        try store.setExistence(for: libro, to: 0, by: .encargada)

        #expect(store.availability(for: libro) == .soldOut)
        #expect(throws: ReservationError.outOfStock) {
            try store.reserve(book: libro, customerName: "Ana", by: .vendedor)
        }
    }

    @Test func unLibroFueraDelInventarioNoSePuedeApartar() {
        let store = makeReservationStore(clock: TestClock())

        #expect(throws: ReservationError.notStocked) {
            try store.reserve(book: makeBook(), customerName: "Ana", by: .vendedor)
        }
    }

    // MARK: - Regla 3: entrega

    @Test(arguments: combinacionesConApartados)
    func entregarBajaUnaUnidadYNoCambiaLosDisponibles(existencia: Int, apartados: Int) throws {
        let store = makeReservationStore(clock: TestClock())
        let libro = makeBook()
        try store.setExistence(for: libro, to: existencia, by: .encargada)
        for indice in 0..<apartados {
            try store.reserve(book: libro, customerName: "Cliente \(indice)", by: .vendedor)
        }
        let disponiblesAntes = try #require(store.stock(for: libro.id)).available

        try store.deliver(folio: 1)

        let resumen = try #require(store.stock(for: libro.id))
        #expect(resumen.existence == existencia - 1)
        #expect(resumen.activeReservations == apartados - 1)
        #expect(resumen.available == disponiblesAntes)
    }

    @Test func entregarCierraElFolio() throws {
        let reloj = TestClock()
        let store = makeReservationStore(clock: reloj)
        let libro = makeBook()
        try store.setExistence(for: libro, to: 3, by: .encargada)
        try store.reserve(book: libro, customerName: "Ana", by: .vendedor)
        reloj.advance(days: 1)

        try store.deliver(folio: 1)

        let folio = try #require(store.reservations.first)
        #expect(folio.status == .entregado)
        #expect(folio.closedAt == reloj.date)
    }

    @Test func unFolioEntregadoNoSePuedeEntregarNiCancelar() throws {
        let store = makeReservationStore(clock: TestClock())
        let libro = makeBook()
        try store.setExistence(for: libro, to: 2, by: .encargada)
        try store.reserve(book: libro, customerName: "Ana", by: .vendedor)
        try store.deliver(folio: 1)

        #expect(throws: ReservationError.folioNotActive(.entregado)) {
            try store.deliver(folio: 1)
        }
        #expect(throws: ReservationError.folioNotActive(.entregado)) {
            try store.cancel(folio: 1)
        }
        // La segunda entrega no bajó otra unidad.
        #expect(store.stock(for: libro.id)?.existence == 1)
    }

    // MARK: - Regla 4: cancelar o vencer

    @Test(arguments: combinacionesConApartados)
    func cancelarLiberaElEjemplar(existencia: Int, apartados: Int) throws {
        let store = makeReservationStore(clock: TestClock())
        let libro = makeBook()
        try store.setExistence(for: libro, to: existencia, by: .encargada)
        for indice in 0..<apartados {
            try store.reserve(book: libro, customerName: "Cliente \(indice)", by: .vendedor)
        }
        let disponiblesAntes = try #require(store.stock(for: libro.id)).available

        try store.cancel(folio: 1)

        let resumen = try #require(store.stock(for: libro.id))
        #expect(resumen.existence == existencia)
        #expect(resumen.available == disponiblesAntes + 1)
        #expect(store.reservations.first?.status == .cancelado)
    }

    @Test func alCancelarElUltimoEjemplarOtroClientePuedeApartarlo() throws {
        let store = makeReservationStore(clock: TestClock())
        let libro = makeBook()
        try store.setExistence(for: libro, to: 1, by: .encargada)
        try store.reserve(book: libro, customerName: "Cliente A", by: .vendedor)
        #expect(store.availability(for: libro) == .soldOut)

        try store.cancel(folio: 1)
        let segundo = try store.reserve(book: libro, customerName: "Cliente B", by: .vendedor)

        // El folio anterior no se reutiliza.
        #expect(segundo.folioLabel == "#002")
    }

    @Test func unFolioVencidoLiberaElEjemplar() throws {
        let reloj = TestClock()
        let store = makeReservationStore(clock: reloj)
        let libro = makeBook()
        try store.setExistence(for: libro, to: 1, by: .encargada)
        let folio = try store.reserve(book: libro, customerName: "Ana", by: .vendedor)
        #expect(store.availability(for: libro) == .soldOut)

        // Pasa justo el plazo.
        reloj.advance(days: ReservationPolicy.standard.expirationDays)
        store.expireOverdue()

        let vencido = try #require(store.reservations.first)
        #expect(vencido.status == .vencido)
        #expect(vencido.closedAt == folio.expiresAt)
        #expect(store.availability(for: libro) == .available(1))
    }

    @Test func antesDelPlazoElFolioSigueActivo() throws {
        let reloj = TestClock()
        let store = makeReservationStore(clock: reloj)
        let libro = makeBook()
        try store.setExistence(for: libro, to: 1, by: .encargada)
        try store.reserve(book: libro, customerName: "Ana", by: .vendedor)

        reloj.advance(days: ReservationPolicy.standard.expirationDays - 1)
        store.expireOverdue()

        #expect(store.reservations.first?.status == .activo)
        #expect(store.availability(for: libro) == .soldOut)
    }

    @Test func unFolioVencidoNoSePuedeEntregar() throws {
        let reloj = TestClock()
        let store = makeReservationStore(clock: reloj)
        let libro = makeBook()
        try store.setExistence(for: libro, to: 1, by: .encargada)
        try store.reserve(book: libro, customerName: "Ana", by: .vendedor)
        reloj.advance(days: ReservationPolicy.standard.expirationDays + 1)

        #expect(throws: ReservationError.folioNotActive(.vencido)) {
            try store.deliver(folio: 1)
        }
        #expect(store.stock(for: libro.id)?.existence == 1)
    }

    @Test func alApartarSeLiberanPrimeroLosFoliosVencidos() throws {
        let reloj = TestClock()
        let store = makeReservationStore(clock: reloj)
        let libro = makeBook()
        try store.setExistence(for: libro, to: 1, by: .encargada)
        try store.reserve(book: libro, customerName: "Cliente A", by: .vendedor)
        reloj.advance(days: ReservationPolicy.standard.expirationDays + 1)

        // Nadie llamó a expireOverdue: apartar lo hace antes de revisar el stock.
        let nuevo = try store.reserve(book: libro, customerName: "Cliente B", by: .vendedor)

        #expect(nuevo.folioLabel == "#002")
        #expect(store.reservations.first?.status == .vencido)
    }

    @Test func elPlazoDeVencimientoEsConfigurable() throws {
        let reloj = TestClock()
        let store = ReservationStore(
            repository: InMemoryReservationRepository(),
            policy: ReservationPolicy(expirationDays: 1),
            now: { reloj.date }
        )
        let libro = makeBook()
        try store.setExistence(for: libro, to: 1, by: .encargada)
        try store.reserve(book: libro, customerName: "Ana", by: .vendedor)

        reloj.advance(days: 1)
        store.expireOverdue()

        #expect(store.reservations.first?.status == .vencido)
        #expect(store.expirationDays == 1)
    }

    // MARK: - Folios

    @Test func losFoliosSonConsecutivosYConFormato() throws {
        let store = makeReservationStore(clock: TestClock())
        let libro = makeBook()
        try store.setExistence(for: libro, to: 3, by: .encargada)

        let folios = try (1...3).map { indice in
            try store.reserve(book: libro, customerName: "Cliente \(indice)", by: .vendedor).folioLabel
        }

        #expect(folios == ["#001", "#002", "#003"])
    }

    @Test func unFolioInexistenteSeRechaza() {
        let store = makeReservationStore(clock: TestClock())

        #expect(throws: ReservationError.folioNotFound) {
            try store.deliver(folio: 99)
        }
        #expect(throws: ReservationError.folioNotFound) {
            try store.cancel(folio: 99)
        }
    }

    @Test func elNombreDelClienteSeRecortaYNoPuedeEstarVacio() throws {
        let store = makeReservationStore(clock: TestClock())
        let libro = makeBook()
        try store.setExistence(for: libro, to: 2, by: .encargada)

        let folio = try store.reserve(book: libro, customerName: "  Ana López \n", by: .vendedor)
        #expect(folio.customerName == "Ana López")

        #expect(throws: ReservationError.invalidCustomerName) {
            try store.reserve(book: libro, customerName: "   ", by: .vendedor)
        }
        #expect(store.reservations.count == 1)
    }

    // MARK: - Ajuste de existencias

    @Test func laExistenciaNoPuedeQuedarPorDebajoDeLosApartadosActivos() throws {
        let store = makeReservationStore(clock: TestClock())
        let libro = makeBook()
        try store.setExistence(for: libro, to: 2, by: .encargada)
        try store.reserve(book: libro, customerName: "Ana", by: .vendedor)
        try store.reserve(book: libro, customerName: "Luis", by: .vendedor)

        #expect(throws: ReservationError.belowActiveReservations(2)) {
            try store.setExistence(for: libro, to: 1, by: .encargada)
        }
        #expect(store.stock(for: libro.id)?.existence == 2)

        // Igual a los apartados sí se permite: disponibles = 0.
        try store.setExistence(for: libro, to: 2, by: .encargada)
        #expect(store.stock(for: libro.id)?.available == 0)
    }

    @Test(arguments: [-1, -10])
    func laExistenciaNoPuedeSerNegativa(cantidad: Int) {
        let store = makeReservationStore(clock: TestClock())

        #expect(throws: ReservationError.invalidQuantity) {
            try store.setExistence(for: makeBook(), to: cantidad, by: .encargada)
        }
        #expect(store.inventory.isEmpty)
    }

    @Test func ajustarUnLibroNuevoLoRegistraEnElInventario() throws {
        let store = makeReservationStore(clock: TestClock())
        let libro = makeBook()
        #expect(store.inventory.isEmpty)

        try store.setExistence(for: libro, to: 4, by: .encargada)

        let item = try #require(store.inventory.first)
        #expect(item.bookID == libro.id)
        #expect(item.title == libro.title)
        #expect(item.author == libro.author)
        #expect(item.coverID == 123)
        #expect(item.existence == 4)
    }

    // MARK: - Almacenamiento

    @Test func elInventarioYLosFoliosSeConservanAlVolverAAbrir() throws {
        let reloj = TestClock()
        let almacenamiento = InMemoryReservationRepository()
        let primera = makeReservationStore(clock: reloj, repository: almacenamiento)
        let libro = makeBook()
        try primera.setExistence(for: libro, to: 3, by: .encargada)
        try primera.reserve(book: libro, customerName: "Ana", by: .vendedor)
        try primera.deliver(folio: 1)
        try primera.reserve(book: libro, customerName: "Luis", by: .encargada)

        // Una tienda nueva sobre el mismo almacenamiento equivale a reabrir la app.
        let segunda = makeReservationStore(clock: reloj, repository: almacenamiento)

        #expect(segunda.stock(for: libro.id) == StockSummary(existence: 2, activeReservations: 1))
        #expect(segunda.reservations.map(\.status) == [.entregado, .activo])
        #expect(segunda.reservations.map(\.customerName) == ["Ana", "Luis"])
        #expect(segunda.reservations.last?.createdBy == .encargada)
    }

    @Test func alAbrirLaAppSeMarcanLosFoliosVencidos() throws {
        let reloj = TestClock()
        let almacenamiento = InMemoryReservationRepository()
        let primera = makeReservationStore(clock: reloj, repository: almacenamiento)
        let libro = makeBook()
        try primera.setExistence(for: libro, to: 1, by: .encargada)
        try primera.reserve(book: libro, customerName: "Ana", by: .vendedor)

        reloj.advance(days: ReservationPolicy.standard.expirationDays + 2)
        let segunda = makeReservationStore(clock: reloj, repository: almacenamiento)

        #expect(segunda.availability(for: libro) == .available(1))
        // El cambio de estado también quedó guardado.
        #expect(almacenamiento.fetchReservations()?.first?.status == .vencido)
    }
}
