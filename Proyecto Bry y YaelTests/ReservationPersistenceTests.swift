import XCTest
import SwiftData
@testable import Proyecto_Bry_y_Yael

// Pruebas del repositorio REAL de SwiftData con una base EN MEMORIA (igual que FavoritesServiceTests):
// no tocan el disco y se repiten igual cada vez.
@MainActor
final class ReservationPersistenceTests: XCTestCase {

    // El contenedor se guarda en una propiedad para que siga vivo durante toda la prueba.
    private var container: ModelContainer?

    private let quijote = InventoryItem(
        bookID: "/works/OL1W",
        title: "Don Quijote de la Mancha",
        author: "Miguel de Cervantes",
        coverID: 123,
        existence: 3
    )

    // Crea un contexto nuevo sobre una base de datos temporal. Incluye también FavoriteBook
    // para comprobar que los modelos nuevos conviven con el esquema anterior.
    private func makeContext() throws -> ModelContext {
        let schema = Schema([
            FavoriteBook.self,
            InventoryRecord.self,
            ReservationRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let newContainer = try ModelContainer(for: schema, configurations: [configuration])
        container = newContainer
        return ModelContext(newContainer)
    }

    private func makeReservation(folio: Int, status: ReservationStatus = .activo) -> Reservation {
        Reservation(
            folio: folio,
            bookID: "/works/OL1W",
            bookTitle: "Don Quijote de la Mancha",
            customerName: "Ana",
            createdBy: .encargada,
            createdAt: Date(timeIntervalSince1970: 1_800_000_000),
            expiresAt: Date(timeIntervalSince1970: 1_800_259_200),
            status: status,
            closedAt: status == .activo ? nil : Date(timeIntervalSince1970: 1_800_100_000)
        )
    }

    // Caso sin resultados: sin guardar nada, no hay inventario ni folios.
    func testFetchIsEmptyWhenNothingWasSaved() throws {
        let repository = SwiftDataReservationRepository(context: try makeContext())

        XCTAssertEqual(repository.fetchInventory()?.count, 0)
        XCTAssertEqual(repository.fetchReservations()?.count, 0)
    }

    // Caso normal: el libro del inventario se guarda con todos sus datos.
    func testInventoryItemRoundTrip() throws {
        let repository = SwiftDataReservationRepository(context: try makeContext())

        repository.save(items: [quijote], reservations: [])

        XCTAssertEqual(repository.fetchInventory(), [quijote])
    }

    // Caso normal: el folio conserva perfil, estado y fechas.
    func testReservationRoundTripKeepsAllFields() throws {
        let repository = SwiftDataReservationRepository(context: try makeContext())
        let folio = makeReservation(folio: 7, status: .entregado)

        repository.save(items: [], reservations: [folio])

        XCTAssertEqual(repository.fetchReservations(), [folio])
    }

    // Caso límite: guardar dos veces el mismo libro o folio lo actualiza, no lo duplica.
    func testSavingTheSameRecordsTwiceUpdatesThemInsteadOfDuplicating() throws {
        let repository = SwiftDataReservationRepository(context: try makeContext())
        var actualizado = quijote
        actualizado.existence = 1
        let activo = makeReservation(folio: 1)
        var cancelado = activo
        cancelado.status = .cancelado
        cancelado.closedAt = Date(timeIntervalSince1970: 1_800_050_000)

        repository.save(items: [quijote], reservations: [activo])
        repository.save(items: [actualizado], reservations: [cancelado])

        XCTAssertEqual(repository.fetchInventory()?.count, 1)
        XCTAssertEqual(repository.fetchInventory()?.first?.existence, 1)
        XCTAssertEqual(repository.fetchReservations()?.count, 1)
        XCTAssertEqual(repository.fetchReservations()?.first?.status, .cancelado)
    }

    // Una entrega guarda el folio cerrado y la existencia en una sola operación.
    func testDeliveryPersistsFolioAndStockTogether() throws {
        let repository = SwiftDataReservationRepository(context: try makeContext())
        let store = ReservationStore(repository: repository)
        let libro = Book(id: quijote.bookID, title: quijote.title, author: quijote.author, description: "")
        try store.setExistence(for: libro, to: 2, by: .encargada)
        try store.reserve(book: libro, customerName: "Ana", by: .vendedor)

        try store.deliver(folio: 1)

        XCTAssertEqual(repository.fetchReservations()?.first?.status, .entregado)
        XCTAssertEqual(repository.fetchInventory()?.first?.existence, 1)
    }

    // Persistencia: una tienda nueva con otro contexto (como al reabrir la app) ve lo guardado.
    func testStockAndFoliosSurviveWithANewContext() throws {
        let firstContext = try makeContext()
        let firstStore = ReservationStore(repository: SwiftDataReservationRepository(context: firstContext))
        let libro = Book(id: quijote.bookID, title: quijote.title, author: quijote.author, description: "")
        try firstStore.setExistence(for: libro, to: 2, by: .encargada)
        try firstStore.reserve(book: libro, customerName: "Ana", by: .vendedor)

        // Otro contexto sobre el mismo contenedor.
        let sameContainer = try XCTUnwrap(container)
        let secondStore = ReservationStore(
            repository: SwiftDataReservationRepository(context: ModelContext(sameContainer))
        )

        XCTAssertEqual(secondStore.stock(for: libro.id), StockSummary(existence: 2, activeReservations: 1))
        XCTAssertEqual(secondStore.reservations.first?.customerName, "Ana")
    }

    // Compatibilidad: los modelos nuevos no afectan a los favoritos del esquema anterior.
    func testFavoritesStillWorkNextToTheNewModels() throws {
        let context = try makeContext()
        let favorites = FavoritesService(context: context)
        let libro = Book(id: quijote.bookID, title: quijote.title, author: quijote.author, description: "")

        favorites.saveFavorite(book: libro)
        SwiftDataReservationRepository(context: context).save(items: [quijote], reservations: [])

        XCTAssertEqual(favorites.fetchFavorites()?.count, 1)
        XCTAssertEqual(favorites.fetchFavorites()?.first?.bookID, libro.id)
    }
}
