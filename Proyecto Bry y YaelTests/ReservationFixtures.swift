import Foundation
@testable import Proyecto_Bry_y_Yael

// Reloj falso: permite avanzar el tiempo para probar el vencimiento de los folios.
@MainActor
final class TestClock {
    var date: Date

    init(date: Date = Date(timeIntervalSince1970: 1_800_000_000)) {
        self.date = date
    }

    func advance(days: Int) {
        date = date.addingTimeInterval(TimeInterval(days) * 86_400)
    }
}

// Libro de prueba. El id tiene la forma de una clave de Open Library.
@MainActor
func makeBook(
    id: String = "/works/OL1W",
    title: String = "Don Quijote de la Mancha",
    author: String = "Miguel de Cervantes"
) -> Book {
    Book(id: id, title: title, author: author, description: "", coverID: 123)
}

// Tienda de apartados con almacenamiento en memoria y un reloj controlado por la prueba.
// Si se pasa un repositorio, varias tiendas pueden compartir lo "guardado" (como al reabrir la app).
@MainActor
func makeReservationStore(
    clock: TestClock,
    repository: (any ReservationRepositoryProtocol)? = nil
) -> ReservationStore {
    ReservationStore(
        repository: repository ?? InMemoryReservationRepository(),
        now: { clock.date }
    )
}
