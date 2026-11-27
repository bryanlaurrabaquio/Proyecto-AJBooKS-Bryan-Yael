import Foundation
import Observation

// ViewModel de la sección "Disponibilidad en el local" del detalle de un libro:
// muestra el stock, permite apartar y, a la encargada, ajustar la existencia.
@MainActor
@Observable
final class BookStockViewModel {
    private let reservations: ReservationStore
    private let profile: ProfileStore
    let book: Book

    // Error al ajustar la existencia (se muestra en una alerta).
    var adjustErrorMessage: String?
    // Error al apartar (se muestra dentro de la hoja de apartado).
    var reserveErrorMessage: String?
    // Confirmación del último folio creado.
    private(set) var confirmationMessage: String?

    init(book: Book, reservations: ReservationStore, profile: ProfileStore) {
        self.book = book
        self.reservations = reservations
        self.profile = profile
    }

    // MARK: - Stock

    // Se lee del ReservationStore, no se guarda una copia aquí.
    var stock: StockSummary? {
        reservations.stock(for: book.id)
    }

    var availability: BookAvailability {
        BookAvailability(summary: stock)
    }

    var availabilityText: String {
        availability.detailText
    }

    var breakdownText: String? {
        guard let stock else {
            return nil
        }

        return "Existencia física: \(stock.existence) · Apartados activos: \(stock.activeReservations)"
    }

    var existence: Int {
        stock?.existence ?? 0
    }

    var canReserve: Bool {
        availability.canReserve
    }

    var expirationDays: Int {
        reservations.expirationDays
    }

    // MARK: - Perfil

    var canAdjustStock: Bool {
        profile.role.canAdjustStock
    }

    // La existencia puede bajar mientras no quede por debajo de los apartados activos.
    var canDecreaseExistence: Bool {
        canAdjustStock && (stock?.available ?? 0) > 0
    }

    var roleNote: String {
        "Perfil activo: \(profile.role.title). Solo la encargada puede ajustar las existencias; el perfil se cambia en la pestaña Apartados."
    }

    // MARK: - Acciones

    // Crea el folio. Devuelve nil (y deja el motivo en reserveErrorMessage) si se rechaza.
    @discardableResult
    func reserve(customerName: String) -> Reservation? {
        do {
            let reservation = try reservations.reserve(
                book: book,
                customerName: customerName,
                by: profile.role
            )

            reserveErrorMessage = nil
            confirmationMessage = "Folio \(reservation.folioLabel) para \(reservation.customerName). Vence el \(reservation.expirationDateText)."

            return reservation
        } catch {
            confirmationMessage = nil
            reserveErrorMessage = error.localizedDescription
            return nil
        }
    }

    func adjustExistence(by delta: Int) {
        do {
            try reservations.setExistence(
                for: book,
                to: existence + delta,
                by: profile.role
            )
            adjustErrorMessage = nil
        } catch {
            adjustErrorMessage = error.localizedDescription
        }
    }

    func clearAdjustError() {
        adjustErrorMessage = nil
    }

    func clearReserveError() {
        reserveErrorMessage = nil
    }

    func clearConfirmation() {
        confirmationMessage = nil
    }
}
