import Foundation
import SwiftData

// Registros persistentes del módulo de apartados.
// Los atributos son tipos simples (los enums se guardan como texto) para que el esquema
// sea fácil de migrar. Son modelos nuevos: no modifican a FavoriteBook.
@Model
class InventoryRecord {
    var bookID: String
    var title: String
    var author: String
    var coverID: Int?
    var existence: Int

    init(
    bookID: String,
    title: String,
    author: String,
    coverID: Int? = nil,
    existence: Int
    ) {
        self.bookID = bookID
        self.title = title
        self.author = author
        self.coverID = coverID
        self.existence = existence
    }
}

@Model
class ReservationRecord {
    var folio: Int
    var bookID: String
    var bookTitle: String
    var customerName: String
    var createdByRaw: String
    var createdAt: Date
    var expiresAt: Date
    var statusRaw: String
    var closedAt: Date?

    init(
    folio: Int,
    bookID: String,
    bookTitle: String,
    customerName: String,
    createdByRaw: String,
    createdAt: Date,
    expiresAt: Date,
    statusRaw: String,
    closedAt: Date? = nil
    ) {
        self.folio = folio
        self.bookID = bookID
        self.bookTitle = bookTitle
        self.customerName = customerName
        self.createdByRaw = createdByRaw
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.statusRaw = statusRaw
        self.closedAt = closedAt
    }
}

// Guarda el inventario y los folios en disco con SwiftData.
class SwiftDataReservationRepository: ReservationRepositoryProtocol {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchInventory() -> [InventoryItem]? {
        do {
            let records = try context.fetch(FetchDescriptor<InventoryRecord>())

            return records
                .map { record in
                    InventoryItem(
                        bookID: record.bookID,
                        title: record.title,
                        author: record.author,
                        coverID: record.coverID,
                        existence: record.existence
                    )
                }
                .sorted { $0.title < $1.title }
        } catch {
            print("Error al leer el inventario: \(error)")
            return nil
        }
    }

    func fetchReservations() -> [Reservation]? {
        do {
            let records = try context.fetch(FetchDescriptor<ReservationRecord>())

            return records
                .map { record in
                    Reservation(
                        folio: record.folio,
                        bookID: record.bookID,
                        bookTitle: record.bookTitle,
                        customerName: record.customerName,
                        // Estos valores los escribe esta misma app; los valores por defecto
                        // solo evitan un cierre si el registro estuviera dañado.
                        createdBy: UserRole(rawValue: record.createdByRaw) ?? .vendedor,
                        createdAt: record.createdAt,
                        expiresAt: record.expiresAt,
                        status: ReservationStatus(rawValue: record.statusRaw) ?? .cancelado,
                        closedAt: record.closedAt
                    )
                }
                .sorted { $0.folio < $1.folio }
        } catch {
            print("Error al leer los apartados: \(error)")
            return nil
        }
    }

    func save(items: [InventoryItem], reservations: [Reservation]) {
        do {
            if !items.isEmpty {
                let existing = try context.fetch(FetchDescriptor<InventoryRecord>())
                var recordsByBookID = Dictionary(
                    existing.map { ($0.bookID, $0) },
                    uniquingKeysWith: { first, _ in first }
                )

                for item in items {
                    if let record = recordsByBookID[item.bookID] {
                        record.title = item.title
                        record.author = item.author
                        record.coverID = item.coverID
                        record.existence = item.existence
                    } else {
                        let record = InventoryRecord(
                            bookID: item.bookID,
                            title: item.title,
                            author: item.author,
                            coverID: item.coverID,
                            existence: item.existence
                        )
                        context.insert(record)
                        recordsByBookID[item.bookID] = record
                    }
                }
            }

            if !reservations.isEmpty {
                let existing = try context.fetch(FetchDescriptor<ReservationRecord>())
                var recordsByFolio = Dictionary(
                    existing.map { ($0.folio, $0) },
                    uniquingKeysWith: { first, _ in first }
                )

                for reservation in reservations {
                    if let record = recordsByFolio[reservation.folio] {
                        record.bookTitle = reservation.bookTitle
                        record.customerName = reservation.customerName
                        record.statusRaw = reservation.status.rawValue
                        record.closedAt = reservation.closedAt
                        record.expiresAt = reservation.expiresAt
                    } else {
                        let record = ReservationRecord(
                            folio: reservation.folio,
                            bookID: reservation.bookID,
                            bookTitle: reservation.bookTitle,
                            customerName: reservation.customerName,
                            createdByRaw: reservation.createdBy.rawValue,
                            createdAt: reservation.createdAt,
                            expiresAt: reservation.expiresAt,
                            statusRaw: reservation.status.rawValue,
                            closedAt: reservation.closedAt
                        )
                        context.insert(record)
                        recordsByFolio[reservation.folio] = record
                    }
                }
            }

            // Un solo guardado para todo: o se escribe completo o no se escribe.
            try context.save()
        } catch {
            print("Error al guardar los apartados: \(error)")
        }
    }
}
