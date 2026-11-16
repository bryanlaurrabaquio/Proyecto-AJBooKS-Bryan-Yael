import SwiftUI
import Translation

// Pantalla 2: Detalle del libro.
// La vista solo muestra y avisa de los toques; el estado "guardado" y la descripción
// los maneja BookDetailViewModel.
struct SecondView: View {
    var viewModel: BookDetailViewModel

    // Estado puramente de interfaz: si se está mostrando la traducción del sistema.
    @State private var isShowingTranslation = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title) private var scaledCoverWidth: CGFloat = 132

    private var coverWidth: CGFloat { min(scaledCoverWidth, 180) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                saveButton
                descriptionSection
                detailsSection
            }
            .padding(Metrics.screenPadding)
            .frame(maxWidth: Metrics.maxContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(Palette.paper.ignoresSafeArea())
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
        // La descripción se consulta al abrir el detalle (si la tarjeta no la pidió antes).
        .task {
            await viewModel.loadDescription()
        }
    }

    // MARK: - Encabezado

    private var header: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
        : AnyLayout(HStackLayout(alignment: .top, spacing: 18))

        return layout {
            BookCoverView(
                url: viewModel.book.coverURL(size: .large),
                title: viewModel.book.title,
                width: coverWidth
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.book.title)
                    .font(.system(.title2, design: .serif, weight: .bold))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                Text(viewModel.book.author)
                    .font(.headline)
                    .foregroundStyle(Palette.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    if let year = viewModel.book.year {
                        InfoTag(text: String(year), systemImage: "calendar")
                    }
                    if let genre = viewModel.book.genre {
                        InfoTag(text: genre, systemImage: "tag")
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Favorito

    private var saveButton: some View {
        Button {
            viewModel.toggleSaved()
        } label: {
            Label(viewModel.buttonTitle, systemImage: viewModel.isSaved ? "heart.fill" : "heart")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 50)
                .foregroundStyle(viewModel.isSaved ? Palette.accent : Palette.onAccent)
                .background(
                    RoundedRectangle(cornerRadius: Metrics.controlCornerRadius, style: .continuous)
                        .fill(viewModel.isSaved ? Palette.surfaceMuted : Palette.accent)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Metrics.controlCornerRadius, style: .continuous)
                        .strokeBorder(Palette.accent, lineWidth: viewModel.isSaved ? 1.5 : 0)
                )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: viewModel.isSaved)
        .accessibilityLabel(viewModel.buttonAccessibilityLabel)
        .accessibilityIdentifier("botonGuardar")
    }

    // MARK: - Descripción

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Descripción")

            switch viewModel.descriptionContent {
            case .loading:
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(Palette.accent)
                    Text(viewModel.descriptionText)
                        .foregroundStyle(Palette.inkSecondary)
                }
                .accessibilityElement(children: .combine)

            // Descripción completa, sin recortes.
            case .text(let text):
                Text(text)
                    .font(.body)
                    .foregroundStyle(Palette.ink)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)

            // Solo existe en otro idioma: se explica y se ofrece la traducción de iOS a petición.
            // El texto traducido lo muestra el sistema; la app no lo presenta como sinopsis oficial.
            case .onlyInOtherLanguage(_, let original):
                VStack(alignment: .leading, spacing: 12) {
                    Label(viewModel.descriptionText, systemImage: "globe")
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        isShowingTranslation = true
                    } label: {
                        Label("Traducir al español", systemImage: "translate")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .translationPresentation(isPresented: $isShowingTranslation, text: original)

                    Text("La traducción la genera iOS en tu dispositivo. Es automática y no es una sinopsis oficial.")
                        .font(.footnote)
                        .foregroundStyle(Palette.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: Metrics.controlCornerRadius, style: .continuous)
                        .fill(Palette.surfaceMuted)
                )

            case .unavailable:
                Label(viewModel.descriptionText, systemImage: "info.circle")
                    .foregroundStyle(Palette.inkSecondary)

            case .failed:
                VStack(alignment: .leading, spacing: 12) {
                    Label(viewModel.descriptionText, systemImage: "wifi.exclamationmark")
                        .foregroundStyle(Palette.error)
                    Button("Reintentar") {
                        Task {
                            await viewModel.retryDescription()
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
    }

    // MARK: - Detalles

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Detalles")

            VStack(spacing: 0) {
                DetailRow(label: "Autoría", value: viewModel.book.author)
                Divider().overlay(Palette.border)
                DetailRow(label: "Primera publicación", value: viewModel.yearText)
                Divider().overlay(Palette.border)
                DetailRow(label: "Género", value: viewModel.genreText)
                Divider().overlay(Palette.border)
                DetailRow(label: "Fuente", value: "Open Library")
            }
            .padding(.horizontal, Metrics.cardPadding)
            .background(CardBackground())
        }
    }
}

// MARK: - Subvistas del detalle

private struct SectionTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(.title3, design: .serif, weight: .semibold))
            .foregroundStyle(Palette.ink)
            .accessibilityAddTraits(.isHeader)
    }
}

private struct InfoTag: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Palette.teal)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Palette.surfaceMuted))
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // Con tamaños grandes de texto, la etiqueta y el valor se apilan.
        let layout = dynamicTypeSize.isAccessibilitySize
        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
        : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 12))

        layout {
            Text(label)
                .foregroundStyle(Palette.inkSecondary)
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: 12)
            }
            Text(value)
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(dynamicTypeSize.isAccessibilitySize ? .leading : .trailing)
        }
        .font(.body)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview("Con descripción") {
    // Datos de ejemplo (Book+Samples.swift): sin red y fáciles de modificar.
    NavigationStack {
        SecondView(
            viewModel: BookDetailViewModel(
                book: Book.samples[0],
                store: .preview()
            )
        )
    }
}

#Preview("Solo en inglés") {
    NavigationStack {
        SecondView(
            viewModel: BookDetailViewModel(
                book: Book.samples[1],
                store: .preview()
            )
        )
    }
    .preferredColorScheme(.dark)
}
#endif
