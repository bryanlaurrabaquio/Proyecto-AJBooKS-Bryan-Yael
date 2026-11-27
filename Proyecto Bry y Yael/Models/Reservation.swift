import Foundation

// Estados de un folio de apartado.
//   activo     -> reserva un ejemplar (cuenta en "Apartados activos").
//   entregado  -> se entregó el libro: el folio se cierra y baja 1 unidad de la existencia.
//   cancelado  -> se canceló: el ejemplar vuelve a estar disponible.
//   vencido    -> pasó la fecha límite sin entregarse: el ejemplar vuelve a estar disponible.
nonisolated enum ReservationStatus: String, CaseIterable {
    case activo
    case entregado
    case cancelado
    case vencido

    var title: String {
        switch self {
        case .activo:
            return "Activo"
        case .entregado:
            return "Entregado"
        case .cancelado:
            return "Cancelado"
        case .vencido:
            return "Vencido"
        }
    }

    var isActive: Bool {
        self == .activo
    }
}

// Un apartado: un ejemplar de un libro reservado para un cliente, con su folio.
nonisolated struct Reservation: Identifiable, Hashable {
    let folio: Int
    let bookID: String
    // Se guarda una copia del título para mostrar el folio aunque el libro ya no salga en la búsqueda.
    var bookTitle: String
    var customerName: String
    let createdBy: UserRole
    let createdAt: Date
    let expiresAt: Date
    var status: ReservationStatus
    var closedAt: Date?

    var id: Int { folio }

    // "#001", "#002"...
    var folioLabel: String {
        String(format: "#%03d", folio)
    }

    // Un folio activo cuya fecha límite ya pasó debe marcarse como vencido.
    func isOverdue(at date: Date) -> Bool {
        status == .activo && expiresAt <= date
    }

    // Fecha límite en el formato del dispositivo, por ejemplo "30 nov 2026".
    var expirationDateText: String {
        expiresAt.formatted(date: .abbreviated, time: .omitted)
    }
}

// Reglas de tiempo de los apartados.
nonisolated struct ReservationPolicy: Equatable {
    // Días que un apartado se conserva antes de vencer.
    var expirationDays: Int

    // SUPUESTO: la presentación no indica el plazo de vencimiento; 3 días es un valor
    // provisional que el equipo debe confirmar con la encargada. Se cambia solo aquí.
    static let standard = ReservationPolicy(expirationDays: 3)

    func expirationDate(from date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: expirationDays, to: date)
            ?? date.addingTimeInterval(TimeInterval(expirationDays) * 86_400)
    }
}
