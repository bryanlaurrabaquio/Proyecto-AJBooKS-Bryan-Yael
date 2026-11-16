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
    // Si no se indica, el ViewModel usa Open Library.
    init(store: BookStore, service: (any BookServicing)? = nil) {
        self.store = store
        _viewModel = State(initialValue: BookListViewModel(store: store, service: service))
    }

    var body: some View {
        // @Bindable permite enlazar searchText del ViewModel con el campo de texto.
        @Bindable var viewModel = viewModel

        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                header
                    .padding(.horizontal, Metrics.screenPadding)

                // La subvista recibe el texto con @Binding (no tiene copia propia).
                SearchField(text: $viewModel.searchText)
                    .padding(.horizontal, Metrics.screenPadding)

                catalog
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .padding(.top, 8)
            .frame(maxWidth: Metrics.maxContentWidth)
            .frame(maxWidth: .infinity)
            .background(Palette.paper.ignoresSafeArea())
            // El encabezado propio sustituye a la barra de navegación en Inicio.
            // El título se usa como texto del botón "atrás" en las otras pantallas.
            .navigationTitle("Inicio")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Book.self) { book in
                SecondView(viewModel: BookDetailViewModel(book: book, store: store))
            }
            // Pide el catálogo a la API al aparecer. Solo descarga si todavía no se había pedido.
            // Como es async, la interfaz no se bloquea mientras espera.
            .task {
                await viewModel.loadIfNeeded()
            }
        }
        .tint(Palette.accent)
    }

    // MARK: - Encabezado

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("BYbooKS")
                    .font(.system(.largeTitle, design: .serif, weight: .bold))
                    .foregroundStyle(Palette.accent)
                    .accessibilityAddTraits(.isHeader)

                Text("Clásicos universales en ediciones en español")
                    .font(.subheadline)
                    .foregroundStyle(Palette.inkSecondary)
            }

            Spacer(minLength: 0)

            // Acceso a Favoritos, con el contador que prepara el ViewModel.
            NavigationLink(destination: FavoritesView(viewModel: FavoritesViewModel(store: store))) {
                Label(String(viewModel.favoritesCount), systemImage: "heart.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Palette.onAccent)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 44)
                    .background(Capsule().fill(Palette.accent))
            }
            .accessibilityLabel(viewModel.favoritesAccessibilityLabel)
            .accessibilityIdentifier("botonFavoritos")
        }
    }

    // MARK: - Catálogo

    // Un case por cada estado de la solicitud (LoadState).
    @ViewBuilder
    private var catalog: some View {
        switch viewModel.state {

        // Loading: indicador mientras se hace la solicitud.
        case .idle, .loading:
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                    .tint(Palette.accent)
                Text("Cargando libros…")
                    .font(.body)
                    .foregroundStyle(Palette.inkSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 48)
            .accessibilityElement(children: .combine)

        // Error: se comunica el problema y se ofrece reintentar.
        case .error(let error):
            StatusMessageView(
                systemImage: error == .connectivity ? "wifi.exclamationmark" : "exclamationmark.triangle",
                title: error.localizedDescription,
                message: error.recoverySuggestion,
                tint: Palette.error,
                actionTitle: "Reintentar",
                action: {
                    Task {
                        await viewModel.retry()
                    }
                }
            )

        // Empty: la consulta funcionó, pero no hay libros para mostrar.
        case .empty:
            StatusMessageView(
                systemImage: "books.vertical",
                title: "No hay libros para mostrar",
                message: "La consulta fue correcta, pero Open Library no devolvió resultados.",
                actionTitle: "Volver a consultar",
                action: {
                    Task {
                        await viewModel.retry()
                    }
                }
            )

        // Content: libros obtenidos del servicio remoto.
        case .content:
            if viewModel.noResults {
                StatusMessageView(
                    systemImage: "magnifyingglass",
                    title: viewModel.noResultsMessage,
                    message: "Prueba con otro título o autor."
                )
            } else {
                bookList
            }
        }
    }

    private var bookList: some View {
        ScrollView {
            // LazyVStack solo crea las tarjetas que se ven en pantalla, así que aguanta muchos libros.
            LazyVStack(alignment: .leading, spacing: Metrics.cardSpacing) {
                Text(viewModel.resultsSummary)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Palette.inkSecondary)

                ForEach(viewModel.filteredBooks) { book in
                    // Navegación basada en datos: la tarjeta envía el libro elegido.
                    BookRow(
                        book: book,
                        descriptionPreview: viewModel.descriptionPreview(for: book),
                        isFavorite: viewModel.isFavorite(book),
                        onToggleFavorite: { viewModel.toggleFavorite(book) }
                    )
                    // La descripción se pide cuando la tarjeta aparece (carga perezosa).
                    .onAppear {
                        viewModel.prefetchDescription(for: book)
                    }
                }
            }
            .padding(.horizontal, Metrics.screenPadding)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

#if DEBUG
// La vista previa usa servicios falsos con datos de ejemplo (Book+Samples.swift).
#Preview("Claro") {
    ContentView(store: .preview(), service: PreviewBookService())
}

#Preview("Oscuro") {
    ContentView(store: .preview(), service: PreviewBookService())
        .preferredColorScheme(.dark)
}
#endif
