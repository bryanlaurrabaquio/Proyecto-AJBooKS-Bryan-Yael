import SwiftUI

// Pantalla 3: Favoritos
struct FavoritesView: View {
    @Environment(BookStore.self) var store

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if store.favoriteBooks.isEmpty {
                    Text("Aún no tienes libros favoritos")
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                }

                ForEach(store.favoriteBooks) { book in
                    // Reutiliza el mismo navigationDestination definido en Inicio.
                    NavigationLink(value: book) {
                        BookRow(book: book, isFavorite: store.isFavorite(book))
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
        FavoritesView()
    }
    .environment(BookStore())
    .preferredColorScheme(.dark)
}
