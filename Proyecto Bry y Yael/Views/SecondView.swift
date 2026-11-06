import SwiftUI

// Pantalla 2: Detalle del libro.
// La vista solo muestra y avisa del toque; el estado "guardado" lo maneja BookDetailViewModel.
struct SecondView: View {
    var viewModel: BookDetailViewModel

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
                    viewModel.toggleSaved()
                }) {
                    HStack {
                        Image(systemName: viewModel.isSaved ? "heart.fill" : "heart")
                        Text(viewModel.buttonTitle)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.isSaved ? Color.red : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .accessibilityLabel(viewModel.buttonAccessibilityLabel)

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
}

#Preview {
    let store = BookStore()
    NavigationStack {
        SecondView(viewModel: BookDetailViewModel(book: store.books[0], store: store))
    }
    .preferredColorScheme(.dark)
}
