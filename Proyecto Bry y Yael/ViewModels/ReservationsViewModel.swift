import Foundation
import Observation

// ViewModel de la pantalla de folios: lista los apartados activos y cerrados
// y permite entregar o cancelar un folio.
@MainActor
@Observable
final class ReservationsViewModel {
    private let reservations: ReservationStore
    private let profile: ProfileStore

    var errorMessage: String?

    init(reservations: ReservationStore, profile: ProfileStore) {
        self.reservations = reservations
        self.profile = profile
    }

    // Más recientes primero.
    var activeFolios: [Reservation] {
        reservations.reservations
            .filter { $0.status.isActive }
            .sorted { $0.folio > $1.folio }
    }

    var closedFolios: [Reservation] {
        reservations.reservations
            .filter { !$0.status.isActive }
            .sorted { $0.folio > $1.folio }
    }

    var isEmpty: Bool {
        reservations.reservations.isEmpty
    }

    // Marca como vencidos los folios cuya fecha límite ya pasó.
    func refresh() {
        reservations.expireOverdue()
    }

    func deliver(_ reservation: Reservation) {
        run {
            try reservations.deliver(folio: reservation.folio)
        }
    }

    func cancel(_ reservation: Reservation) {
        run {
            try reservations.cancel(folio: reservation.folio)
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func run(_ action: () throws -> Void) {
        do {
            try action()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Textos

    // Línea de fecha según el estado del folio.
    func detailLine(for reservation: Reservation) -> String {
        let closed = (reservation.closedAt ?? reservation.expiresAt)
            .formatted(date: .abbreviated, time: .omitted)

        switch reservation.status {
        case .activo:
            return "Vence el \(reservation.expirationDateText)"
        case .entregado:
            return "Entregado el \(closed)"
        case .cancelado:
            return "Cancelado el \(closed)"
        case .vencido:
            return "Venció el \(closed)"
        }
    }

    func customerLine(for reservation: Reservation) -> String {
        "Cliente: \(reservation.customerName) · Apartó: \(reservation.createdBy.title)"
    }

    func accessibilitySummary(for reservation: Reservation) -> String {
        "Folio \(reservation.folioLabel), \(reservation.bookTitle), \(reservation.status.title.lowercased()). \(customerLine(for: reservation)). \(detailLine(for: reservation))"
    }
}
