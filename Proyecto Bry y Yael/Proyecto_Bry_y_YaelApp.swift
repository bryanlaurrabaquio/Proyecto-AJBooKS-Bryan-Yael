import Foundation
import SwiftUI
import SwiftData

// Punto de entrada de BYbooKS.
// El nombre del tipo y del target se conservan ("Proyecto Bry y Yael") para no romper
// el módulo que importan las pruebas ni la ubicación de los datos guardados con SwiftData.
@main
struct Proyecto_Bry_y_YaelApp: App {
    // El contenedor se guarda como propiedad para que siga vivo mientras la app está abierta.
    let container: ModelContainer

    // El BookStore se crea una sola vez, por encima de todas las vistas.
    // Se le pasa a ContentView, que lo reparte a los ViewModels (no hay copias).
    @State var store: BookStore

    init() {
        // Caché más amplia para las portadas: AsyncImage usa URLSession.shared,
        // que guarda las imágenes en URLCache.shared. Así no se descargan otra vez al desplazarse.
        URLCache.shared = URLCache(
            memoryCapacity: 30 * 1024 * 1024,
            diskCapacity: 150 * 1024 * 1024
        )

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
            _store = State(initialValue: BookStore(
                favoritesService: service,
                descriptionService: OpenLibraryService()
            ))
        } catch {
            fatalError("No se pudo crear el ModelContainer de SwiftData: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            // Sin .preferredColorScheme: la paleta tiene variantes para modo claro y oscuro
            // y la app sigue la configuración del sistema.
            ContentView(store: store)
        }
    }
}
