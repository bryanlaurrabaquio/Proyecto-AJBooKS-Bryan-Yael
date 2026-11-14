import SwiftUI

// Pantalla 3: Favoritos.
// La lista y el "está vacía" los prepara FavoritesViewModel.
struct FavoritesView: View {
    var viewModel: FavoritesViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if viewModel.isEmpty {
                    Text("Aún no tienes libros favoritos")
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                }

                ForEach(viewModel.favorites) { book in
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
    // Store en memoria con un par de favoritos de ejemplo.
    NavigationStack {
        FavoritesView(
            viewModel: FavoritesViewModel(
                store: .preview(favorites: Array(Book.samples.prefix(2)))
            )
        )
    }
    .preferredColorScheme(.dark)
}
