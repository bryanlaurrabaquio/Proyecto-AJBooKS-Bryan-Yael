import SwiftUI

// Pantalla 3: Favoritos.
// La lista, el "está vacía" y las descripciones los prepara FavoritesViewModel.
struct FavoritesView: View {
    var viewModel: FavoritesViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Metrics.cardSpacing) {
                if viewModel.isEmpty {
                    StatusMessageView(
                        systemImage: "heart",
                        title: "Aún no tienes libros favoritos",
                        message: "Toca el corazón de cualquier libro para guardarlo aquí. Tus favoritos se conservan aunque cierres la app."
                    )
                    .padding(.top, 24)
                }

                ForEach(viewModel.favorites) { book in
                    // Reutiliza el mismo navigationDestination definido en Inicio.
                    BookRow(
                        book: book,
                        descriptionPreview: viewModel.descriptionPreview(for: book),
                        isFavorite: viewModel.isFavorite(book),
                        onToggleFavorite: {
                            withAnimation {
                                viewModel.removeFavorite(book)
                            }
                        }
                    )
                    .onAppear {
                        viewModel.prefetchDescription(for: book)
                    }
                }
            }
            .padding(Metrics.screenPadding)
            .frame(maxWidth: Metrics.maxContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Palette.paper.ignoresSafeArea())
        .navigationTitle("Favoritos")
    }
}

#if DEBUG
#Preview {
    // Store en memoria con un par de favoritos de ejemplo.
    NavigationStack {
        FavoritesView(
            viewModel: FavoritesViewModel(
                store: .preview(favorites: Array(Book.samples.prefix(2)))
            )
        )
    }
}

#Preview("Vacío") {
    NavigationStack {
        FavoritesView(viewModel: FavoritesViewModel(store: .preview()))
    }
}
#endif
