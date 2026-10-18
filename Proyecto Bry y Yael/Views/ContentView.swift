import SwiftUI

// Pantalla 1: Inicio (lista de libros con búsqueda)
struct ContentView: View {
    @Environment(BookStore.self) var store

    // Estado local: el texto de búsqueda solo importa en esta pantalla.
    @State var searchText = ""

    // Libros que coinciden con la búsqueda (early return).
    var filteredBooks: [Book] {
        if searchText == "" {
            return store.books
        }
        return store.books.filter { book in
            book.title.lowercased().contains(searchText.lowercased())
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("AJBooks")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.red)

                    Spacer()

                    // Acceso a Favoritos, con el contador que viene del BookStore.
                    NavigationLink(destination: FavoritesView()) {
                        HStack {
                            Image(systemName: "heart.fill")
                            Text(String(store.favorites.count))
                        }
                        .foregroundColor(.red)
                    }
                    .accessibilityLabel("Ver favoritos")
                }

                Text("Libros en tendencia")
                    .foregroundColor(.gray)

                // La subvista recibe el texto con @Binding (no tiene copia propia).
                SearchField(text: $searchText)

                if filteredBooks.isEmpty {
                    Text("No se encontraron libros para " + searchText)
                        .foregroundColor(.gray)
                        .padding(.top)
                }

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(filteredBooks) { book in
                            // Navegación basada en datos: se envía el libro elegido.
                            NavigationLink(value: book) {
                                BookRow(book: book)
                            }
                        }
                    }
                }
            }
            .padding()
            .navigationDestination(for: Book.self) { book in
                SecondView(book: book)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(BookStore())
        .preferredColorScheme(.dark)
}
