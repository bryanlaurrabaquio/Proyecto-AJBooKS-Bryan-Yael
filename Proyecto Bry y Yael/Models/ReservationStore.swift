import Foundation
import Observation

// Fuente única de verdad del módulo de apartados: inventario del local y folios.
// Aquí viven las reglas del piloto; las vistas y los ViewModels no las repiten:
//
//   1. Disponibles = Existencia física − Apartados activos.
//   2. Último ejemplar: si dos personas piden el mismo libro y solo queda uno, solo una obtiene folio.
//   3. Entrega: cierra el folio y baja 1 unidad de la existencia.
//   4. Cancelar o vencer: el ejemplar vuelve a estar disponible.
//   5. Permisos: solo la encargada ajusta las existencias.
//
// Todo corre en el MainActor y cada operación es síncrona: revisar el stock y crear el folio
// ocurren sin que otra solicitud se intercale, por eso el último ejemplar nunca se entrega dos veces.
// Esto garantiza la regla en un solo dispositivo; con varios dispositivos haría falta un servidor.
@MainActor
@Observable
final class ReservationStore {

    // Libros que el local tiene en inventario.
    private(set) var inventory: [InventoryItem] = []

    // Todos los folios, de cualquier estado.
    private(set) var reservations: [Reservation] = []

    private let repository: any ReservationRepositoryProtocol
    private let policy: ReservationPolicy
    // El reloj se puede sustituir en las pruebas para probar el vencimiento.
    private let now: () -> Date

    // Si no se indica un almacenamiento se usa uno en memoria. Se crea dentro del init
    // (en el MainActor) para evitar advertencias de aislamiento de actores.
    init(
        repository: (any ReservationRepositoryProtocol)? = nil,
        policy: ReservationPolicy = .standard,
        now: @escaping () -> Date = { Date() }
    ) {
        self.repository = repository ?? InMemoryReservationRepository()
        self.policy = policy
        self.now = now

        load()
        expireOverdue()
    }

    func load() {
        inventory = repository.fetchInventory() ?? []
        reservations = repository.fetchReservations() ?? []
    }

    // Días que dura un apartado (para avisarlo al apartar).
    var expirationDays: Int {
        policy.expirationDays
    }

    // MARK: - Consultas

    // nil = el libro no está en el inventario del local.
    func stock(for bookID: String) -> StockSummary? {
        guard let item = inventory.first(where: { $0.bookID == bookID }) else {
            return nil
        }

        return StockSummary(
            existence: item.existence,
            activeReservations: activeCount(for: bookID)
        )
    }

    func availability(for book: Book) -> BookAvailability {
        BookAvailability(summary: stock(for: book.id))
    }

    private func activeCount(for bookID: String) -> Int {
        reservations.filter { $0.bookID == bookID && $0.status.isActive }.count
    }

    private var nextFolio: Int {
        // Los folios nunca se reutilizan, aunque el anterior se cancele o venza.
        (reservations.map(\.folio).max() ?? 0) + 1
    }

    // MARK: - Apartar

    // Crea un folio para un cliente. Rechaza la solicitud si no hay ejemplares disponibles.
    @discardableResult
    func reserve(book: Book, customerName: String, by role: UserRole) throws -> Reservation {
        expireOverdue()

        let customer = customerName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !customer.isEmpty else {
            throw ReservationError.invalidCustomerName
        }

        guard let summary = stock(for: book.id) else {
            throw ReservationError.notStocked
        }

        guard summary.available > 0 else {
            throw ReservationError.outOfStock
        }

        let createdAt = now()

        let reservation = Reservation(
            folio: nextFolio,
            bookID: book.id,
            bookTitle: book.title,
            customerName: customer,
            createdBy: role,
            createdAt: createdAt,
            expiresAt: policy.expirationDate(from: createdAt),
            status: .activo,
            closedAt: nil
        )

        reservations.append(reservation)
        repository.save(items: [], reservations: [reservation])

        return reservation
    }

    // MARK: - Entregar y cancelar

    // Cierra el folio y baja 1 unidad de la existencia. Los dos cambios se guardan juntos.
    func deliver(folio: Int) throws {
        expireOverdue()

        let index = try activeReservationIndex(folio: folio)
        let bookID = reservations[index].bookID

        guard let itemIndex = inventory.firstIndex(where: { $0.bookID == bookID }),
              inventory[itemIndex].existence > 0 else {
            throw ReservationError.outOfStock
        }

        reservations[index].status = .entregado
        reservations[index].closedAt = now()
        inventory[itemIndex].existence -= 1

        repository.save(items: [inventory[itemIndex]], reservations: [reservations[index]])
    }

    // El ejemplar vuelve a estar disponible.
    func cancel(folio: Int) throws {
        expireOverdue()

        let index = try activeReservationIndex(folio: folio)

        reservations[index].status = .cancelado
        reservations[index].closedAt = now()

        repository.save(items: [], reservations: [reservations[index]])
    }

    private func activeReservationIndex(folio: Int) throws -> Int {
        guard let index = reservations.firstIndex(where: { $0.folio == folio }) else {
            throw ReservationError.folioNotFound
        }

        let status = reservations[index].status

        guard status.isActive else {
            throw ReservationError.folioNotActive(status)
        }

        return index
    }

    // MARK: - Vencimiento

    // Marca como vencidos los folios activos cuya fecha límite ya pasó.
    // El ejemplar vuelve a estar disponible porque el folio deja de contar como activo.
    // Se llama al abrir la app, al abrir la pantalla de apartados y antes de cada operación.
    func expireOverdue() {
        let current = now()
        var changed: [Reservation] = []

        for index in reservations.indices where reservations[index].isOverdue(at: current) {
            reservations[index].status = .vencido
            reservations[index].closedAt = reservations[index].expiresAt
            changed.append(reservations[index])
        }

        if !changed.isEmpty {
            repository.save(items: [], reservations: changed)
        }
    }

    // MARK: - Inventario

    // Fija la existencia física de un libro (y lo registra en el inventario si no estaba).
    // Solo la encargada puede hacerlo, y la existencia no puede quedar por debajo
    // de los apartados activos.
    func setExistence(for book: Book, to quantity: Int, by role: UserRole) throws {
        guard role.canAdjustStock else {
            throw ReservationError.notAllowed
        }

        guard quantity >= 0 else {
            throw ReservationError.invalidQuantity
        }

        expireOverdue()

        let active = activeCount(for: book.id)

        guard quantity >= active else {
            throw ReservationError.belowActiveReservations(active)
        }

        let item = InventoryItem(
            bookID: book.id,
            title: book.title,
            author: book.author,
            coverID: book.coverID,
            existence: quantity
        )

        if let index = inventory.firstIndex(where: { $0.bookID == book.id }) {
            inventory[index] = item
        } else {
            inventory.append(item)
        }

        repository.save(items: [item], reservations: [])
    }
}
