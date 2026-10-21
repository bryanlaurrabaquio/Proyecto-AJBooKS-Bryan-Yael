import SwiftUI

// Pantalla 1: Inicio (lista de libros con búsqueda).
// La vista solo dibuja y avisa de las acciones; las reglas viven en BookListViewModel.
struct ContentView: View {
    // El ViewModel se crea una sola vez con el BookStore que llega desde la App.
    @State var viewModel: BookListViewModel

    // Se guarda para pasárselo a los ViewModels de las pantallas a las que se navega.
    let store: BookStore

    init(store: BookStore) {
        self.store = store
        _viewModel = State(initialValue: BookListViewModel(store: store))
    }

    var body: some View {
        // @Bindable permite enlazar searchText del ViewModel con el campo de texto.
        @Bindable var viewModel = viewModel

        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("AJBooks")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.red)

                    Spacer()

                    // Acceso a Favoritos, con el contador que prepara el ViewModel.
                    NavigationLink(destination: FavoritesView(viewModel: FavoritesViewModel(store: store))) {
                        HStack {
                            Image(systemName: "heart.fill")
                            Text(String(viewModel.favoritesCount))
                        }
                        .foregroundColor(.red)
                    }
                    .accessibilityLabel("Ver favoritos")
                }

                Text("Libros en tendencia")
                    .foregroundColor(.gray)

                // La subvista recibe el texto con @Binding (no tiene copia propia).
                SearchField(text: $viewModel.searchText)

                if viewModel.noResults {
                    Text("No se encontraron libros para " + viewModel.searchText)
                        .foregroundColor(.gray)
                        .padding(.top)
                }

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(viewModel.filteredBooks) { book in
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
                SecondView(viewModel: BookDetailViewModel(book: book, store: store))
            }
        }
    }
}

#Preview {
    ContentView(store: BookStore())
        .preferredColorScheme(.dark)
}
