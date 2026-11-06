import SwiftUI
import SwiftData

@main
struct Proyecto_Bry_y_YaelApp: App {
    // El contenedor se guarda como propiedad para que siga vivo mientras la app está abierta.
    let container: ModelContainer

    // El BookStore se crea una sola vez, por encima de todas las vistas.
    // Se le pasa a ContentView, que lo reparte a los ViewModels (no hay copias).
    @State var store: BookStore

    init() {
        // Configuración de SwiftData (igual que en TMDB):
        // esquema con el modelo persistente, guardado en disco (isStoredInMemoryOnly: false).
        let schema = Schema([
            FavoriteBook.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.container = container

            // El servicio recibe el contexto y se lo da al BookStore.
            let service = FavoritesService(context: ModelContext(container))
            _store = State(initialValue: BookStore(favoritesService: service))
        } catch {
            fatalError("No se pudo crear el ModelContainer de SwiftData: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .preferredColorScheme(.dark)
        }
    }
}
