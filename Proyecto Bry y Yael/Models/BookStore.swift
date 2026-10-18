import SwiftUI

// Single Source of Truth: aquí viven la lista de libros y los favoritos.
// Las vistas no guardan copias; leen y modifican este objeto compartido.
@Observable
class BookStore {
    var books: [Book] = [
        Book(title: "La Odisea", author: "Homero", year: "Desconocido", genre: "Aventura", description: "Tras la guerra de Troya, Odiseo emprende un largo viaje de regreso a su hogar en Ítaca."),
        Book(title: "El principito", author: "Antoine de Saint-Exupéry", year: "1943", genre: "Fantasía", description: "Un piloto perdido en el desierto conoce a un pequeño príncipe que viene de otro planeta."),
        Book(title: "Cien años de soledad", author: "Gabriel García Márquez", year: "1967", genre: "Realismo mágico", description: "La historia de varias generaciones de la familia Buendía en el pueblo de Macondo."),
        Book(title: "Pedro Páramo", author: "Juan Rulfo", year: "1955", genre: "Realismo mágico", description: "Juan Preciado llega a Comala buscando a su padre y encuentra un pueblo lleno de murmullos."),
        Book(title: "Don Quijote de la Mancha", author: "Miguel de Cervantes", year: "1605", genre: "Clásico", description: "Un hidalgo sale a buscar aventuras como caballero andante junto a Sancho Panza."),
        Book(title: "Frankenstein", author: "Mary Shelley", year: "1818", genre: "Terror", description: "Un científico da vida a una criatura y tiene que enfrentar las consecuencias.")
    ]

    // Guardamos solo los ids de los favoritos para no duplicar los libros.
    var favoriteIDs: [UUID] = []

    // Los favoritos se calculan a partir de la lista única de libros.
    var favorites: [Book] {
        books.filter { book in
            favoriteIDs.contains(book.id)
        }
    }

    func isFavorite(_ book: Book) -> Bool {
        return favoriteIDs.contains(book.id)
    }

    func toggleFavorite(_ book: Book) {
        if isFavorite(book) {
            favoriteIDs.removeAll { id in
                id == book.id
            }
        } else {
            favoriteIDs.append(book.id)
        }
    }
}
