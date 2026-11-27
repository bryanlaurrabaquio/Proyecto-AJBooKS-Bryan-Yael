import SwiftUI

// Subvista reutilizable: la misma fila se usa en Inicio y en Favoritos.
struct BookRow: View {
    var book: Book

    // Inventario del local. Es opcional: en vistas previas o pruebas puede no haberlo
    // y entonces la tarjeta se ve igual que antes.
    @Environment(ReservationStore.self) private var reservations: ReservationStore?

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

                // Stock del local: "Disponibles: N" o "Sin stock". Si el libro no está en el
                // inventario no se muestra nada.
                if let availability = reservations?.availability(for: book) {
                    AvailabilityChip(availability: availability)
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

