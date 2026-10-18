import SwiftUI

// Pantalla 2: Detalle del libro
struct SecondView: View {
    @Environment(BookStore.self) var store
    var book: Book

    // El estado de favorito se lee del BookStore, no de un @State local.
    var saved: Bool {
        return store.isFavorite(book)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "book.closed")
                        .font(.system(size: 50))
                        .frame(width: 120, height: 170)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(10)
                        .accessibilityLabel("Portada de " + book.title)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(book.title)
                            .font(.title2)
                            .bold()

                        Text(book.author)
                            .foregroundColor(.gray)
                    }
                }

                Button(action: {
                    store.toggleFavorite(book)
                }) {
                    HStack {
                        Image(systemName: saved ? "heart.fill" : "heart")
                        Text(saved ? "Guardado" : "Guardar")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(saved ? Color.red : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .accessibilityLabel(saved ? "Quitar de favoritos" : "Guardar en favoritos")

                Text("Descripción")
                    .font(.headline)

                Text(book.description)
                    .foregroundColor(.gray)

                Text("Autor: " + book.author)
                Text("Año: " + book.year)
                Text("Género: " + book.genre)
            }
            .padding()
        }
        .navigationTitle("Detalle")
    }
}

#Preview {
    NavigationStack {
        SecondView(book: BookStore().books[0])
    }
    .environment(BookStore())
    .preferredColorScheme(.dark)
}
