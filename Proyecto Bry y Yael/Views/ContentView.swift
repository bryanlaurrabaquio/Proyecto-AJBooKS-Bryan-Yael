import SwiftUI

// Pantalla 1: Inicio. Muestra el catálogo que llega de Open Library
// y representa sus cuatro estados: cargando, contenido, vacío y error.
// La vista no conoce la API: solo lee el estado que prepara BookListViewModel.

enum AppRoute: Hashable{
    case favorites
}

struct ContentView: View {
    // El ViewModel se crea una sola vez con el BookStore que llega desde la App.
    @State var viewModel: BookListViewModel
    @State private var favoritesViewModel: FavoritesViewModel

    // Se guarda para pasárselo a los ViewModels de las pantallas a las que se navega.
    let store: BookStore

    // El servicio se puede sustituir (por ejemplo, en la vista previa) sin tocar la red.
    // Si no se indica, el ViewModel usa Open Library.
    init(store: BookStore, service: (any BookServicing)? = nil) {
        self.store = store
        _viewModel = State(initialValue: BookListViewModel(store: store, service: service))
        _favoritesViewModel = State(initialValue: FavoritesViewModel(store: store))
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

                    NavigationLink(value: AppRoute.favorites) {
                        HStack {
                            Image(systemName: "heart.fill")
                            Text(String(viewModel.favoritesCount))
                        }
                        .foregroundColor(.appAccent)
                    }
                    .accessibilityLabel("Ver favoritos")
                }

                Text(viewModel.hasSearchText ? "Resultados de búsqueda" : "Libros en tendencia")
                    .foregroundColor(.appMuted)

                // La subvista recibe el texto con @Binding (no tiene copia propia).
                SearchField(text: $viewModel.searchText)
                    // Al presionar "Buscar" se consulta Open Library de inmediato.
                    .onSubmit {
                        Task {
                            await viewModel.search()
                        }
                    }
                    // Cada vez que cambia el texto se busca sola en Open Library tras una pausa corta.
                    // Si el usuario sigue escribiendo, SwiftUI cancela la tarea anterior.
                    .task(id: viewModel.searchText) {
                        await viewModel.searchAfterTyping()
                    }

                if viewModel.hasSearchText {
                    searchResults
                } else {
                    catalog
                }
            }
            .padding()
            // Ocupa toda la pantalla aunque haya poco contenido (un mensaje o un indicador):
            // así el contenido queda arriba y el fondo crema cubre todo, no solo una franja.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            // Fondo crema también detrás de la barra de navegación.
            .background(Color.appBackground.ignoresSafeArea())
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .navigationDestination(for: Book.self) { book in
                SecondView(viewModel: BookDetailViewModel(book: book, store: store))
            }
            .navigationDestination(for: AppRoute.self){route in switch route{

                    case .favorites:
                        FavoritesView(viewModel: favoritesViewModel)
                    
                }
                
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
            bookList(viewModel.books)
                // Al jalar hacia abajo se cambian los 10 libros por otros al azar.
                .refreshable {
                    await viewModel.refreshRandomBooks()
                }
        }
    }

    // Resultados mientras hay texto: coincidencias locales al instante
    // más los libros que encuentra Open Library.
    @ViewBuilder
    private var searchResults: some View {
        let books = viewModel.searchResults

        if !books.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                // Aviso discreto mientras llegan más resultados de Open Library.
                if viewModel.isSearchingOnline {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text(viewModel.searchingMessage)
                    }
                    .font(.footnote)
                    .foregroundColor(.appMuted)
                    .accessibilityElement(children: .combine)
                }

                bookList(books)
            }
        } else {
            switch viewModel.searchState {

            case .idle, .loading, .content:
                ProgressView(viewModel.searchingMessage)
                    .foregroundColor(.appMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)

            case .error(let error):
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.appAccent)

                    Text(error.localizedDescription)
                        .foregroundColor(.appText)
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
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.appAccent)
                        .accessibilityHidden(true)

                    Text(viewModel.noMatchesMessage)
                        .foregroundColor(.appMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            }
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
