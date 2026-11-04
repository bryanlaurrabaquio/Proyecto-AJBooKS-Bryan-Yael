import SwiftUI
import SwiftData

struct SecondView: View {
    var viewModel: BookDetailViewModel

    // El contexto permite insertar, eliminar y guardar.
    @Environment(\.modelContext) var context

    // Lo guardado hasta ahora; la vista se redibuja sola cuando cambia.
    @Query var saved: [FavoriteBook]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image(systemName: "book.closed")
                        .font(.system(size: 50))
                        .frame(width: 120, height: 170)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(10)
                        .accessibilityLabel("Portada de " + viewModel.book.title)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.book.title)
                            .font(.title2)
                            .bold()

                        Text(viewModel.book.author)
                            .foregroundColor(.gray)
                    }
                }

                Button(action: {
                    toggleSaved()
                }) {
                    HStack {
                        Image(systemName: viewModel.isSaved(in: saved) ? "heart.fill" : "heart")
                        Text(viewModel.buttonTitle(in: saved))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isSaved(in: saved) ? Color.red : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .accessibilityLabel(viewModel.buttonAccessibilityLabel(in: saved))

                Text("Descripción")
                    .font(.headline)

                Text(viewModel.book.description)
                    .foregroundColor(.gray)

                Text("Autor: " + viewModel.book.author)
                Text("Año: " + viewModel.book.year)
                Text("Género: " + viewModel.book.genre)
            }
            .padding()
        }
        .navigationTitle("Detalle")
    }

    // Si ya está guardado lo elimina; si no, lo inserta.
    // Solo inserta cuando NO existe, así que nunca se duplica.
    func toggleSaved() {
        if let item = viewModel.savedItem(in: saved) {
            context.delete(item)
        } else {
            context.insert(viewModel.makeFavorite())
        }

        do {
            try context.save()
        } catch {
            print("No se pudo guardar: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        SecondView(viewModel: BookDetailViewModel(book: BookStore().books[0]))
    }
    .modelContainer(for: FavoriteBook.self, inMemory: true)
    .preferredColorScheme(.dark)
}
