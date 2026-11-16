import SwiftUI

// Subvista reutilizable: la misma fila se usa en Inicio y en Favoritos.
struct BookRow: View {
    var book: Book

    var body: some View {
        HStack {
            AsyncImage(url: book.coverURL()) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "book.closed")
                    .font(.largeTitle)
                    .foregroundColor(.appMuted)
            }
            .frame(width: 60, height: 80)
            .background(Color.appCover)
            .cornerRadius(6)
            .accessibilityLabel("Portada de " + book.title)

            VStack(alignment: .leading, spacing: 5) {
                Text(book.title)
                    .font(.headline)
                    .foregroundColor(.appText)

                Text(book.author)
                    .foregroundColor(.appMuted)

                // El formato "año - género" viene del Model (Book.subtitle).
                // Si el libro no tiene ninguno de los dos datos, no se muestra la línea.
                if let subtitle = book.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.appAccent)
                }
            }

            Spacer()
        }
        .padding(10)
        .background(Color.appCard)
        .cornerRadius(10)
    }
}

#Preview {
    BookRow(book: Book.samples[0])
}

// Paleta de la app: base café, en tonos claros.
// Todos los colores salen de aquí, así que para cambiar la paleta solo se editan estas líneas.
extension Color {
    static let appBackground = Color(hex: 0xE6D6BD)   // crema oscuro (fondo de las pantallas)
    static let appCard = Color(hex: 0xFAF3E8)         // crema claro (tarjetas, resaltan sobre el fondo)
    static let appCover = Color(hex: 0xE3D2BC)        // fondo de las portadas
    static let appAccent = Color(hex: 0x9C4F1B)       // café canela (título, año/género, botones)
    static let appText = Color(hex: 0x3E2A1C)         // café oscuro (textos principales)
    static let appMuted = Color(hex: 0x75594A)        // café grisáceo (autor, descripciones)
    static let appInactive = Color(hex: 0x8C7B6B)     // botón "Guardar" sin guardar

    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
