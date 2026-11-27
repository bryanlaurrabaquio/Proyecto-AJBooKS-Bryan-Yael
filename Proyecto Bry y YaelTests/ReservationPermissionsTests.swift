import Foundation
import Testing
@testable import Proyecto_Bry_y_Yael

// Pruebas de permisos: solo la encargada ajusta las existencias.
// La regla se valida en ReservationStore, no solo escondiendo botones en la interfaz.
// Ojo: los perfiles son un selector de la app, no una cuenta con contraseña; estas pruebas
// comprueban la separación de funciones del piloto, no una defensa contra un atacante.
@MainActor
struct ReservationPermissionsTests {

    @Test(arguments: [(UserRole.vendedor, false), (UserRole.encargada, true)])
    func soloLaEncargadaPuedeAjustarExistencias(perfil: UserRole, permitido: Bool) {
        #expect(perfil.canAdjustStock == permitido)
    }

    @Test func elVendedorNoPuedeAjustarExistencias() {
        let almacenamiento = InMemoryReservationRepository()
        let store = makeReservationStore(clock: TestClock(), repository: almacenamiento)

        #expect(throws: ReservationError.notAllowed) {
            try store.setExistence(for: makeBook(), to: 5, by: .vendedor)
        }

        // El intento rechazado no cambió nada, ni en memoria ni en lo guardado.
        #expect(store.inventory.isEmpty)
        #expect(almacenamiento.fetchInventory()?.isEmpty == true)
    }

    @Test func laEncargadaPuedeAjustarExistencias() throws {
        let store = makeReservationStore(clock: TestClock())
        let libro = makeBook()

        try store.setExistence(for: libro, to: 5, by: .encargada)

        #expect(store.stock(for: libro.id)?.existence == 5)
    }

    @Test func unIntentoRechazadoNoCambiaUnaExistenciaYaRegistrada() throws {
        let store = makeReservationStore(clock: TestClock())
        let libro = makeBook()
        try store.setExistence(for: libro, to: 3, by: .encargada)

        #expect(throws: ReservationError.notAllowed) {
            try store.setExistence(for: libro, to: 10, by: .vendedor)
        }
        #expect(throws: ReservationError.notAllowed) {
            try store.setExistence(for: libro, to: 0, by: .vendedor)
        }

        #expect(store.stock(for: libro.id)?.existence == 3)
    }

    @Test(arguments: UserRole.allCases)
    func cualquierPerfilPuedeApartarYQuedaRegistradoQuienLoHizo(perfil: UserRole) throws {
        let store = makeReservationStore(clock: TestClock())
        let libro = makeBook()
        try store.setExistence(for: libro, to: 1, by: .encargada)

        let folio = try store.reserve(book: libro, customerName: "Ana", by: perfil)

        #expect(folio.createdBy == perfil)
    }

    @Test func elPerfilInicialEsElDeMenosPermisos() {
        #expect(ProfileStore().role == .vendedor)
    }

    @Test func elMensajeDeNoPermitidoEstaEnEspanol() {
        #expect(ReservationError.notAllowed.errorDescription == "Solo la encargada puede ajustar las existencias.")
    }

    // MARK: - Desde la interfaz (ViewModels)

    @Test func cambiarDePerfilActivaLosPermisosEnElDetalle() throws {
        let store = makeReservationStore(clock: TestClock())
        let perfil = ProfileStore(role: .vendedor)
        let viewModel = BookStockViewModel(book: makeBook(), reservations: store, profile: perfil)

        #expect(viewModel.canAdjustStock == false)
        viewModel.adjustExistence(by: 1)
        #expect(viewModel.existence == 0)
        #expect(viewModel.adjustErrorMessage == "Solo la encargada puede ajustar las existencias.")

        perfil.role = .encargada
        viewModel.clearAdjustError()
        viewModel.adjustExistence(by: 1)

        #expect(viewModel.canAdjustStock)
        #expect(viewModel.existence == 1)
        #expect(viewModel.adjustErrorMessage == nil)
    }

    @Test func elInventarioNoDejaAjustarAlVendedor() throws {
        let store = makeReservationStore(clock: TestClock())
        let libro = makeBook()
        try store.setExistence(for: libro, to: 2, by: .encargada)
        let perfil = ProfileStore(role: .vendedor)
        let viewModel = InventoryViewModel(reservations: store, profile: perfil)
        let fila = try #require(viewModel.rows.first)

        #expect(viewModel.canAdjustStock == false)
        #expect(viewModel.canDecrease(fila) == false)

        viewModel.increase(fila)

        #expect(store.stock(for: libro.id)?.existence == 2)
        #expect(viewModel.errorMessage != nil)
    }

    @Test func elVendedorPuedeEntregarYCancelarFolios() throws {
        let store = makeReservationStore(clock: TestClock())
        let libro = makeBook()
        try store.setExistence(for: libro, to: 2, by: .encargada)
        try store.reserve(book: libro, customerName: "Ana", by: .vendedor)
        try store.reserve(book: libro, customerName: "Luis", by: .vendedor)
        let viewModel = ReservationsViewModel(
            reservations: store,
            profile: ProfileStore(role: .vendedor)
        )

        viewModel.deliver(store.reservations[0])
        viewModel.cancel(store.reservations[1])

        #expect(viewModel.errorMessage == nil)
        #expect(store.reservations.map(\.status) == [.entregado, .cancelado])
    }
}
