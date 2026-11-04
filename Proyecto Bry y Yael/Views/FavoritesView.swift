import SwiftUI
import SwiftData

struct FavoritesView: View {
    var viewModel: FavoritesViewModel

    // La lista se actualiza sola con lo que haya guardado.
    @Query var saved: [FavoriteBook]

    var body: some View {
        let books = viewModel.favoriteBooks(from: saved)

        ScrollView {
            VStack(spacing: 10) {
                if books.isEmpty {
                    Text("Aún no tienes libros favoritos")
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                }

                ForEach(books) { book in
                    NavigationLink(value: book) {
                        BookRow(book: book)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Favoritos")
    }
}

#Preview {
    NavigationStack {
        FavoritesView(viewModel: FavoritesViewModel(store: BookStore()))
    }
    .modelContainer(for: FavoriteBook.self, inMemory: true)
    .preferredColorScheme(.dark)
}
