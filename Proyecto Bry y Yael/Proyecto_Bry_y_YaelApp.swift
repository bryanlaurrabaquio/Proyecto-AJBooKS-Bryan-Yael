import SwiftUI
import SwiftData

@main
struct Proyecto_Bry_y_YaelApp: App {
    @State var store = BookStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .preferredColorScheme(.dark)
        }
        // Crea el ModelContainer y deja el ModelContext disponible
        // en todas las vistas (para @Query y @Environment).
        .modelContainer(for: FavoriteBook.self)
    }
}
