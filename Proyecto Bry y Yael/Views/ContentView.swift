import SwiftUI
import SwiftData

struct ContentView: View {
    @State var viewModel: BookListViewModel
    let store: BookStore

    // @Query se actualiza solo cuando cambia la colección personal.
    @Query var favorites: [FavoriteBook]

    init(store: BookStore) {
        self.store = store
        _viewModel = State(initialValue: BookListViewModel(store: store))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("AJBooks")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.red)

                    Spacer()

                    NavigationLink(destination: FavoritesView(viewModel: FavoritesViewModel(store: store))) {
                        HStack {
                            Image(systemName: "heart.fill")
                            // El contador sale directamente de lo guardado.
                            Text(String(favorites.count))
                        }
                        .foregroundColor(.red)
                    }
                    .accessibilityLabel("Ver favoritos")
                }

                Text("Libros en tendencia")
                    .foregroundColor(.gray)

                SearchField(text: $viewModel.searchText)

                if viewModel.noResults {
                    Text("No se encontraron libros para " + viewModel.searchText)
                        .foregroundColor(.gray)
                        .padding(.top)
                }

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(viewModel.filteredBooks) { book in
                            NavigationLink(value: book) {
                                BookRow(book: book)
                            }
                        }
                    }
                }
            }
            .padding()
            .navigationDestination(for: Book.self) { book in
                SecondView(viewModel: BookDetailViewModel(book: book))
            }
        }
    }
}

#Preview {
    ContentView(store: BookStore())
        .modelContainer(for: FavoriteBook.self, inMemory: true)
        .preferredColorScheme(.dark)
}
