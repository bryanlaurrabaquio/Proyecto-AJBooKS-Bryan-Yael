import SwiftUI

// Portada de un libro con proporción fija de 2:3 (la de la mayoría de los libros).
// Contempla todos los estados de la descarga:
//   - sin URL (el libro no tiene portada)   -> portada de respaldo de BYbooKS
//   - cargando                              -> indicador de progreso
//   - imagen disponible                     -> la portada recortada sin deformarse
//   - error (404, sin red)                  -> portada de respaldo de BYbooKS
struct BookCoverView: View {
    let url: URL?
    let title: String
    let width: CGFloat
    // En las tarjetas el título ya se lee junto a la portada; ahí la imagen es decorativa.
    var isDecorative: Bool = false

    private var height: CGFloat { width * 1.5 }
    private let cornerRadius: CGFloat = 8

    var body: some View {
        cover
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Palette.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            .accessibilityHidden(isDecorative)
    }

    @ViewBuilder
    private var cover: some View {
        if let url {
            AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.25))) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .accessibilityLabel("Portada de \(title)")

                case .empty:
                    CoverPlaceholder(isLoading: true)
                        .accessibilityLabel("Cargando portada de \(title)")

                case .failure:
                    CoverPlaceholder(isLoading: false)
                        .accessibilityLabel("Portada no disponible")

                @unknown default:
                    CoverPlaceholder(isLoading: false)
                        .accessibilityLabel("Portada no disponible")
                }
            }
        } else {
            CoverPlaceholder(isLoading: false)
                .accessibilityLabel("Portada no disponible")
        }
    }
}

// Portada de respaldo con la identidad de BYbooKS.
// No imita una portada real: muestra el logotipo de texto y "Sin portada".
private struct CoverPlaceholder: View {
    let isLoading: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Palette.surfaceMuted, Palette.paper],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if isLoading {
                ProgressView()
                    .tint(Palette.accent)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "book.closed")
                        .font(.title2)
                        .foregroundStyle(Palette.accent)
                    Text("BYbooKS")
                        .font(.system(.caption, design: .serif, weight: .bold))
                        .foregroundStyle(Palette.accent)
                    Text("Sin portada")
                        .font(.caption2)
                        .foregroundStyle(Palette.inkSecondary)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(6)
                // El respaldo es un gráfico de tamaño fijo: se limita el crecimiento del texto.
                .dynamicTypeSize(...DynamicTypeSize.xLarge)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isImage)
    }
}

#if DEBUG
#Preview("Portadas") {
    HStack(spacing: 16) {
        BookCoverView(url: Book.samples[0].coverURL(size: .medium), title: "La Odisea", width: 90)
        BookCoverView(url: nil, title: "Libro sin portada", width: 90)
    }
    .padding()
    .background(Palette.paper)
}
#endif
