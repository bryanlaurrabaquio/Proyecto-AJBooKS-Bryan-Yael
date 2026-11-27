import SwiftUI

// Pantalla 2: Detalle del libro.
// La vista solo muestra y avisa del toque; el estado "guardado" lo maneja BookDetailViewModel.
struct SecondView: View {
    @State var viewModel: BookDetailViewModel

    init(viewModel: BookDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    AsyncImage(url: viewModel.book.coverURL(size: "L")) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "book.closed")
                            .font(.system(size: 50))
                    }
                    .frame(width: 120, height: 170)
                    .background(Color.appCover)
                    .cornerRadius(10)
                    .accessibilityLabel("Portada de " + viewModel.book.title)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.book.title)
                            .font(.title2)
                            .bold()

                        Text(viewModel.book.author)
                            .foregroundColor(.appMuted)
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
                    .background(viewModel.isSaved ? Color.appAccent : Color.appInactive)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .accessibilityLabel(viewModel.buttonAccessibilityLabel)

                // Stock del local, apartar y (para la encargada) ajustar la existencia.
                StockSection(book: viewModel.book)

                Text("Descripción")
                    .font(.headline)

                Text(viewModel.descriptionText)
                .foregroundColor(.appMuted)

                Text("Autor: " + viewModel.book.author)
                Text("Año: " + viewModel.yearText)
                Text("Género: " + viewModel.genreText)
            }
            .padding()
            // Texto principal en café oscuro; los que tienen su propio color lo conservan.
            .foregroundColor(.appText)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .navigationTitle("Detalle")
        .task {
            await viewModel.loadDescription()
        }
    }
}


#Preview {
    // Datos de ejemplo (Book+Samples.swift): sin red y fáciles de modificar.
    NavigationStack {
        SecondView(
            viewModel: BookDetailViewModel(
                book: Book.samples[0],
                store: BookStore()
            )
        )
    }
}
