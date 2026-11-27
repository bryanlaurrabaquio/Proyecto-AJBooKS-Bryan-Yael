import Foundation
import Observation

// Un libro del inventario con sus existencias ya calculadas.
nonisolated struct InventoryRow: Identifiable, Equatable {
    let item: InventoryItem
    let summary: StockSummary

    var id: String { item.bookID }
}

// ViewModel del inventario: lista los libros del local con su stock
// y, si el perfil activo es la encargada, permite ajustar la existencia.
@MainActor
@Observable
final class InventoryViewModel {
    private let reservations: ReservationStore
    private let profile: ProfileStore

    var errorMessage: String?

    init(reservations: ReservationStore, profile: ProfileStore) {
        self.reservations = reservations
        self.profile = profile
    }

    var rows: [InventoryRow] {
        reservations.inventory
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
            .compactMap { item in
                reservations.stock(for: item.bookID).map { summary in
                    InventoryRow(item: item, summary: summary)
                }
            }
    }

    var isEmpty: Bool {
        reservations.inventory.isEmpty
    }

    var canAdjustStock: Bool {
        profile.role.canAdjustStock
    }

    var roleNote: String {
        if canAdjustStock {
            return "Perfil activo: Encargada. Puedes ajustar las existencias."
        }

        return "Perfil activo: \(profile.role.title). Solo la encargada puede ajustar las existencias."
    }

    // La existencia puede bajar mientras no quede por debajo de los apartados activos.
    func canDecrease(_ row: InventoryRow) -> Bool {
        canAdjustStock && row.summary.available > 0
    }

    func increase(_ row: InventoryRow) {
        adjust(row, by: 1)
    }

    func decrease(_ row: InventoryRow) {
        adjust(row, by: -1)
    }

    func clearError() {
        errorMessage = nil
    }

    private func adjust(_ row: InventoryRow, by delta: Int) {
        do {
            try reservations.setExistence(
                for: row.item.asBook,
                to: row.summary.existence + delta,
                by: profile.role
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func accessibilitySummary(for row: InventoryRow) -> String {
        "\(row.item.title), \(row.item.author). Existencia física \(row.summary.existence), apartados activos \(row.summary.activeReservations), disponibles \(row.summary.available)."
    }
}
