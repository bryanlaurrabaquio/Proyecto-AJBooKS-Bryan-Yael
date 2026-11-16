import SwiftUI

// Tarjeta reutilizable de un libro: la misma se usa en Inicio y en Favoritos.
// La zona de portada y texto abre el detalle; el corazón es un botón aparte
// (no está anidado dentro del enlace, así cada toque hace solo una cosa).
struct BookRow: View {
    let book: Book
    let descriptionPreview: DescriptionPreview
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    // La portada crece un poco con Dynamic Type, con un máximo para no quitar espacio al texto.
    @ScaledMetric(relativeTo: .body) private var scaledCoverWidth: CGFloat = 84

    private var coverWidth: CGFloat { min(scaledCoverWidth, 120) }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            NavigationLink(value: book) {
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Abre el detalle del libro")

            FavoriteToggleButton(
                isFavorite: isFavorite,
                bookTitle: book.title,
                action: onToggleFavorite
            )
        }
        .padding(Metrics.cardPadding)
        .background(CardBackground())
    }

    // Con tamaños de accesibilidad la portada pasa arriba y el texto usa todo el ancho.
    private var content: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
        : AnyLayout(HStackLayout(alignment: .top, spacing: Metrics.cardSpacing))

        return layout {
            BookCoverView(
                url: book.coverURL(size: .medium),
                title: book.title,
                width: coverWidth,
                isDecorative: true
            )

            info
        }
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(book.title)
                .font(.system(.headline, design: .serif))
                .foregroundStyle(Palette.ink)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 3)
                .fixedSize(horizontal: false, vertical: true)

            Text(book.author)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Palette.inkSecondary)
                .lineLimit(2)

            // El formato "año - género" viene del Model (Book.subtitle).
            // Si el libro no tiene ninguno de los dos datos, no se muestra la línea.
            if let subtitle = book.subtitle {
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.teal)
            }

            descriptionView
                .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var descriptionView: some View {
        switch descriptionPreview {
        case .loading:
            Text("Cargando la descripción de este libro para mostrar un resumen.")
                .font(.footnote)
                .lineLimit(2)
                .redacted(reason: .placeholder)
                .accessibilityLabel("Cargando descripción")

        case .summary(let text):
            Text(text)
                .font(.footnote)
                .foregroundStyle(Palette.ink)
                .lineSpacing(2)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 6 : 3)

        case .notice(let message):
            Label(message, systemImage: "info.circle")
                .font(.footnote.italic())
                .foregroundStyle(Palette.inkSecondary)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        VStack(spacing: 14) {
            BookRow(
                book: Book.samples[0],
                descriptionPreview: .summary("Texto de ejemplo para la vista previa de la tarjeta."),
                isFavorite: true,
                onToggleFavorite: {}
            )
            BookRow(
                book: Book.samples[1],
                descriptionPreview: .notice("Descripción disponible solo en inglés"),
                isFavorite: false,
                onToggleFavorite: {}
            )
        }
        .padding()
        .background(Palette.paper)
    }
}
#endif
