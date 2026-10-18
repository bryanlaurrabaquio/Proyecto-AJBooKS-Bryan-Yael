import SwiftUI

// Pantalla 3: Favoritos
struct FavoritesView: View {
    @Environment(BookStore.self) var store

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if store.favorites.isEmpty {
                    Text("Aún no tienes libros favoritos")
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                }

                ForEach(store.favorites) { book in
                    // Reutiliza el mismo navigationDestination definido en Inicio.
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
        FavoritesView()
    }
    .environment(BookStore())
    .preferredColorScheme(.dark)
}
