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
                    Text("BYbooKS")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.appAccent)

                    Spacer()

                    // Acceso a Favoritos, con el contador que prepara el ViewModel.
                    NavigationLink(destination: FavoritesView(viewModel: FavoritesViewModel(store: store))) {
                        HStack {
                            Image(systemName: "heart.fill")
                            Text(String(viewModel.favoritesCount))
                        }
                        .foregroundColor(.appAccent)
                    }
                    .accessibilityLabel("Ver favoritos")
                }

                Text(viewModel.isShowingSearchResults ? "Resultados de Open Library" : "Libros en tendencia")
                    .foregroundColor(.appMuted)

                // La subvista recibe el texto con @Binding (no tiene copia propia).
                SearchField(text: $viewModel.searchText)
                    // Al presionar "Buscar" se consulta toda la base de Open Library.
                    .onSubmit {
                        Task {
                            await viewModel.search()
                        }
                    }
                    // Si el usuario edita el texto, se vuelve a la lista de inicio.
                    .onChange(of: viewModel.searchText) {
                        viewModel.resetSearch()
                    }

                if viewModel.isShowingSearchResults {
                    searchResults
                } else {
                    catalog
                }
            }
            .padding()
            // Fondo crema también detrás de la barra de navegación.
            .background(Color.appBackground.ignoresSafeArea())
            .toolbarBackground(Color.appBackground, for: .navigationBar)
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
                    .foregroundColor(.appAccent)

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
                    .foregroundColor(.appMuted)
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
                Text("No se encontraron libros para " + viewModel.searchText + " en esta lista. Presiona Buscar para buscar en Open Library.")
                    .foregroundColor(.appMuted)
                    .padding(.top)
            } else {
                bookList(viewModel.filteredBooks)
                    // Al jalar hacia abajo se cambian los 10 libros por otros al azar.
                    .refreshable {
                        await viewModel.refreshRandomBooks()
                    }
            }
        }
    }

    // Resultados de buscar en toda la base de Open Library (mismos estados que el catálogo).
    @ViewBuilder
    private var searchResults: some View {
        switch viewModel.searchState {

        case .idle, .loading:
            ProgressView("Buscando en Open Library…")
                .frame(maxWidth: .infinity)
                .padding(.top, 40)

        case .error(let error):
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.appAccent)

                Text(error.localizedDescription)
                    .multilineTextAlignment(.center)

                Button("Reintentar") {
                    Task {
                        await viewModel.search()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)

        case .empty:
            Text("Open Library no encontró libros para " + viewModel.searchText)
                .foregroundColor(.appMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 40)

        case .content(let books):
            bookList(books)
        }
    }

    // Lista de libros que se usa en el catálogo y en los resultados de búsqueda.
    // List solo crea las filas que se ven en pantalla, así que aguanta muchos libros.
    private func bookList(_ books: [Book]) -> some View {
        List(books) { book in
            // Navegación basada en datos: se envía el libro elegido.
            NavigationLink(value: book) {
                BookRow(book: book)
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
        }
        .listStyle(.plain)
        // Sin esto, la lista pinta su propio fondo y tapa el color crema.
        .scrollContentBackground(.hidden)
    }
}

// La vista previa usa un servicio falso con datos de ejemplo (Book+Samples.swift).
#Preview {
    ContentView(store: BookStore(), service: PreviewBookService())
}
