import SwiftUI
import SwiftData

@main
struct Proyecto_Bry_y_YaelApp: App {
    // El contenedor se guarda como propiedad para que siga vivo mientras la app está abierta.
    let container: ModelContainer

    // El BookStore se crea una sola vez, por encima de todas las vistas.
    // Se le pasa a ContentView, que lo reparte a los ViewModels (no hay copias).
    @State var store: BookStore

    // Inventario y folios del módulo de apartados (también una sola instancia para toda la app).
    @State var reservations: ReservationStore

    // Perfil activo del local (vendedor o encargada).
    @State var profile: ProfileStore

    init() {
        // Configuración de SwiftData (igual que en TMDB):
        // esquema con los modelos persistentes, guardado en disco (isStoredInMemoryOnly: false).
        // Los dos modelos de apartados son nuevos: SwiftData los agrega sin tocar los favoritos guardados.
        let schema = Schema([
            FavoriteBook.self,
            InventoryRecord.self,
            ReservationRecord.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.container = container

            // El servicio recibe el contexto y se lo da al BookStore.
            let service = FavoritesService(context: ModelContext(container))
            _store = State(initialValue: BookStore(favoritesService: service))

            // Lo mismo para el inventario y los folios.
            let repository = SwiftDataReservationRepository(context: ModelContext(container))
            _reservations = State(initialValue: ReservationStore(repository: repository))
            _profile = State(initialValue: ProfileStore())
        } catch {
            fatalError("No se pudo crear el ModelContainer de SwiftData: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            // Dos pestañas: Libros (ContentView) y Apartados.
            RootView(store: store, reservations: reservations, profile: profile)
                // Botones, enlaces y flecha de regreso en café (en vez del azul del sistema).
                .tint(Color.appAccent)
                // Siempre tema claro, para que la paleta se vea igual con el sistema en modo oscuro.
                .preferredColorScheme(.light)
        }
    }
}
