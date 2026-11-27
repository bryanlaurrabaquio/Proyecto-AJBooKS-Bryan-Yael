import Foundation

// Contrato de almacenamiento del inventario y los folios.
// Trabaja con los modelos de la app (InventoryItem y Reservation), no con registros de SwiftData:
// así las reglas de ReservationStore se prueban sin disco.
protocol ReservationRepositoryProtocol {
    // nil = falló la lectura.
    func fetchInventory() -> [InventoryItem]?
    func fetchReservations() -> [Reservation]?

    // Inserta o actualiza (por bookID y por folio) todo lo indicado en una sola operación,
    // para que una entrega nunca deje el folio cerrado sin haber bajado la existencia.
    func save(items: [InventoryItem], reservations: [Reservation])
}

// Almacenamiento en memoria. Se usa en vistas previas y pruebas.
final class InMemoryReservationRepository: ReservationRepositoryProtocol {

    private var itemsByBookID: [String: InventoryItem] = [:]
    private var reservationsByFolio: [Int: Reservation] = [:]

    func fetchInventory() -> [InventoryItem]? {
        itemsByBookID.values.sorted { $0.title < $1.title }
    }

    func fetchReservations() -> [Reservation]? {
        reservationsByFolio.values.sorted { $0.folio < $1.folio }
    }

    func save(items: [InventoryItem], reservations: [Reservation]) {
        for item in items {
            itemsByBookID[item.bookID] = item
        }

        for reservation in reservations {
            reservationsByFolio[reservation.folio] = reservation
        }
    }
}
