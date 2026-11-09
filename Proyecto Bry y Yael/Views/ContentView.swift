import SwiftUI

// Pantalla 1: Inicio. Muestra el catálogo que llega de Open Library
// y representa sus cuatro estados: cargando, contenido, vacío y error.
// La vista no conoce la API: solo lee el estado que prepara BookListViewModel.
struct ContentView: View {
    // El ViewModel se crea una sola vez con el BookStore que llega desde la App.
    @State var viewModel: BookListViewModel

    // Se guarda para pasárselo a los ViewModels de las pantallas a las que se navega.
    let store: BookStore

    // El servicio se puede sustituir (por ejemplo, en la vista previa) sin tocar la red.
    init(store: BookStore, service: any BookServicing = OpenLibraryService()) {
        self.store = store
        _viewModel = State(initialValue: BookListViewModel(store: store, service: service))
    }

    var body: some View {
        // @Bindable permite enlazar searchText del ViewModel con el campo de texto.
        @Bindable var viewModel = viewModel

        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("AJBooks")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.red)

                    Spacer()

                    // Acceso a Favoritos, con el contador que prepara el ViewModel.
                    NavigationLink(destination: FavoritesView(viewModel: FavoritesViewModel(store: store))) {
                        HStack {
                            Image(systemName: "heart.fill")
                            Text(String(viewModel.favoritesCount))
                        }
                        .foregroundColor(.red)
                    }
                    .accessibilityLabel("Ver favoritos")
                }

                Text("Libros en tendencia")
                    .foregroundColor(.gray)

                // La subvista recibe el texto con @Binding (no tiene copia propia).
                SearchField(text: $viewModel.searchText)

                catalog
            }
            .padding()
            .navigationDestination(for: Book.self) { book in
                SecondView(viewModel: BookDetailViewModel(book: book, store: store))
            }
            // Pide el catálogo a la API al aparecer. Solo descarga si todavía no se había pedido.
            // Como es async, la interfaz no se bloquea mientras espera.
            .task {
                await viewModel.loadIfNeeded()
            }
        }
    }

    // Un case por cada estado de la solicitud (LoadState).
    @ViewBuilder
    private var catalog: some View {
        switch viewModel.state {

        // Loading: indicador mientras se hace la solicitud.
        case .idle, .loading:
            ProgressView("Cargando libros…")
                .frame(maxWidth: .infinity)
                .padding(.top, 40)

        // Error: se comunica el problema y se ofrece reintentar.
        case .error(let error):
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.red)

                Text(error.localizedDescription)
                    .multilineTextAlignment(.center)

                Button("Reintentar") {
                    Task {
                        await viewModel.retry()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)

        // Empty: la consulta funcionó, pero no hay libros para mostrar.
        case .empty:
            VStack(spacing: 12) {
                Text("La consulta fue correcta, pero no hay libros para mostrar.")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                Button("Volver a consultar") {
                    Task {
                        await viewModel.retry()
                    }
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)

        // Content: libros obtenidos del servicio remoto.
        case .content:
            if viewModel.noResults {
                Text("No se encontraron libros para " + viewModel.searchText)
                    .foregroundColor(.gray)
                    .padding(.top)
            } else {
                // List solo crea las filas que se ven en pantalla, así que aguanta muchos libros.
                List(viewModel.filteredBooks) { book in
                    // Navegación basada en datos: se envía el libro elegido.
                    NavigationLink(value: book) {
                        BookRow(book: book)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                }
                .listStyle(.plain)
            }
        }
    }
}

// La vista previa usa un servicio falso con datos de ejemplo (Book+Samples.swift).
#Preview {
    ContentView(store: BookStore(), service: PreviewBookService())
        .preferredColorScheme(.dark)
}
