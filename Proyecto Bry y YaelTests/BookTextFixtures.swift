@testable import Proyecto_Bry_y_Yael

@MainActor
func makeSeededStore(
favoritesService: any FavoritesServiceProtocol =
InMemoryFavoritesService()
) -> BookStore {

    let store = BookStore(
        favoritesService: favoritesService
    )

    store.catalogState = .content([
        Book(
            id: "local-odisea",
            title: "La Odisea",
            author: "Homero",
            year: "Desconocido",
            genre: "Aventura",
            description: ""
        ),
        Book(
            id: "local-principito",
            title: "El principito",
            author: "Antoine de Saint-Exupéry",
            year: "1943",
            genre: "Fantasía",
            description: ""
        ),
        Book(
            id: "local-cien-anos",
            title: "Cien años de soledad",
            author: "Gabriel García Márquez",
            year: "1967",
            genre: "Realismo mágico",
            description: ""
        ),
        Book(
            id: "local-pedro-paramo",
            title: "Pedro Páramo",
            author: "Juan Rulfo",
            year: "1955",
            genre: "Realismo mágico",
            description: ""
        ),
        Book(
            id: "local-quijote",
            title: "Don Quijote de la Mancha",
            author: "Miguel de Cervantes",
            year: "1605",
            genre: "Clásico",
            description: ""
        ),
        Book(
            id: "local-frankenstein",
            title: "Frankenstein",
            author: "Mary Shelley",
            year: "1818",
            genre: "Terror",
            description: ""
        )
    ])

    return store
}
