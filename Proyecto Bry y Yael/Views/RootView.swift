import SwiftUI

// Raíz de la app: dos pestañas, Libros (catálogo, búsqueda y favoritos) y Apartados (folios e inventario).
// Inyecta en el entorno el ReservationStore y el perfil para que la tarjeta del libro
// (BookRow) y el detalle (StockSection) muestren la disponibilidad sin cambiar sus inicializadores.
struct RootView: View {
    let store: BookStore
    let reservations: ReservationStore
    let profile: ProfileStore

    var body: some View {
        TabView {
            ContentView(store: store)
                .tabItem {
                    Label("Libros", systemImage: "books.vertical")
                }

            ReservationsView(reservations: reservations, profile: profile)
                .tabItem {
                    Label("Apartados", systemImage: "bookmark")
                }
        }
        .environment(reservations)
        .environment(profile)
    }
}

#if DEBUG
#Preview {
    RootView(
        store: BookStore(),
        reservations: ReservationStore(),
        profile: ProfileStore()
    )
}
#endif
