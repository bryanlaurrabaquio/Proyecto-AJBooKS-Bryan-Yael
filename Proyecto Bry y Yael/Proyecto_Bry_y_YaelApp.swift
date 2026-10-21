import SwiftUI

@main
struct Proyecto_Bry_y_YaelApp: App {
    // El BookStore se crea una sola vez, por encima de todas las vistas.
    // Se le pasa a ContentView, que lo reparte a los ViewModels (no hay copias).
    @State var store = BookStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .preferredColorScheme(.dark)
        }
    }
}
