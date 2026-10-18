import SwiftUI

// Inicio conserva la búsqueda en su ViewModel y comparte el catálogo y favoritos.
struct ContentView: View {
    @Environment(BookStore.self) private var store
    @State private var viewModel = BookListViewModel()

    private var filteredBooks: [Book] {
        viewModel.filteredBooks(from: store.books)
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

                    NavigationLink(destination: FavoritesView()) {
                        HStack {
                            Image(systemName: "heart.fill")
                            Text(String(store.favoriteBooks.count))
                        }
                        .foregroundColor(.red)
                    }
                    .accessibilityLabel("Ver favoritos")
                }

                Text("Libros en tendencia")
                    .foregroundColor(.gray)

                SearchField(text: $viewModel.searchText)

                if filteredBooks.isEmpty {
                    ContentUnavailableView.search(text: viewModel.trimmedSearchText)
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(filteredBooks) { book in
                                NavigationLink(value: book) {
                                    BookRow(book: book, isFavorite: store.isFavorite(book))
                                }
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
