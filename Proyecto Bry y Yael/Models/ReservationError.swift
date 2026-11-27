import Foundation

// Motivos por los que una operación de apartados se rechaza.
nonisolated enum ReservationError: Error, Equatable {
    // El perfil activo no tiene permiso (por ejemplo, un vendedor quiere ajustar existencias).
    case notAllowed
    // No hay ejemplares disponibles.
    case outOfStock
    // El libro no está en el inventario del local.
    case notStocked
    case invalidCustomerName
    case invalidQuantity
    // La existencia no puede quedar por debajo de los apartados activos (el valor indica cuántos hay).
    case belowActiveReservations(Int)
    case folioNotFound
    // El folio ya no está activo (entregado, cancelado o vencido).
    case folioNotActive(ReservationStatus)
}

nonisolated extension ReservationError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .notAllowed:
            return "Solo la encargada puede ajustar las existencias."

        case .outOfStock:
            return "Sin stock: todos los ejemplares están apartados o no hay existencia."

        case .notStocked:
            return "Este libro todavía no está en el inventario del local."

        case .invalidCustomerName:
            return "Escribe el nombre del cliente."

        case .invalidQuantity:
            return "La existencia no puede ser negativa."

        case .belowActiveReservations(let active):
            return "La existencia no puede ser menor que los apartados activos (\(active))."

        case .folioNotFound:
            return "No se encontró el folio."

        case .folioNotActive(let status):
            return "El folio ya está \(status.title.lowercased())."
        }
    }
}
