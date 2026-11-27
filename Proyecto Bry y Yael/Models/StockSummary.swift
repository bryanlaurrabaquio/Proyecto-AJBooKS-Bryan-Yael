import Foundation

// Resumen de existencias de un libro del inventario.
nonisolated struct StockSummary: Equatable {
    // Existencia física: ejemplares que hay en el local.
    let existence: Int
    // Apartados activos: folios que están reservando un ejemplar.
    let activeReservations: Int

    // Regla central del módulo:  Disponibles = Existencia física − Apartados activos.
    var available: Int {
        existence - activeReservations
    }
}

// Lo que se muestra de un libro en la búsqueda y en el detalle.
nonisolated enum BookAvailability: Equatable {
    // El local no maneja inventario de este libro.
    case notStocked
    // Hay ejemplares sin apartar.
    case available(Int)
    // No hay existencia o todos los ejemplares están apartados.
    case soldOut

    init(summary: StockSummary?) {
        guard let summary else {
            self = .notStocked
            return
        }

        self = summary.available > 0 ? .available(summary.available) : .soldOut
    }

    var canReserve: Bool {
        if case .available = self {
            return true
        }
        return false
    }

    // Texto corto para la tarjeta del libro. nil = no se muestra nada.
    var chipText: String? {
        switch self {
        case .notStocked:
            return nil
        case .available(let count):
            return "Disponibles: \(count)"
        case .soldOut:
            return "Sin stock"
        }
    }

    // Texto para el detalle del libro.
    var detailText: String {
        switch self {
        case .notStocked:
            return "Este libro todavía no está en el inventario del local."
        case .available(let count):
            return "Disponibles: \(count)"
        case .soldOut:
            return "Sin stock"
        }
    }
}
