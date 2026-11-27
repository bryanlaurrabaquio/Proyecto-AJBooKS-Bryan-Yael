import SwiftUI

// Tarjeta de un folio. Los folios activos muestran los botones Entregar y Cancelar.
// La vista solo dibuja; los textos los prepara ReservationsViewModel.
struct ReservationRow: View {
    let reservation: Reservation
    let customerLine: String
    let detailLine: String
    let accessibilitySummary: String
    let onDeliver: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("Folio \(reservation.folioLabel)")
                    .font(.headline)
                    .foregroundColor(.appAccent)

                Spacer()

                Text(reservation.status.title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(reservation.status.isActive ? .white : .appText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(reservation.status.isActive ? Color.appAccent : Color.appCover)
                    )
            }

            Text(reservation.bookTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.appText)

            Text(customerLine)
                .font(.footnote)
                .foregroundColor(.appMuted)

            Text(detailLine)
                .font(.footnote)
                .foregroundColor(.appMuted)

            if reservation.status.isActive {
                HStack(spacing: 12) {
                    Button("Entregar", action: onDeliver)
                        .buttonStyle(.borderedProminent)
                        .accessibilityHint("Cierra el folio y baja una unidad de la existencia")

                    Button("Cancelar", role: .destructive, action: onCancel)
                        .buttonStyle(.bordered)
                        .accessibilityHint("Libera el ejemplar para que vuelva a estar disponible")
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.appCard)
        .cornerRadius(10)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilitySummary)
    }
}

#Preview {
    ReservationRow(
        reservation: Reservation(
            folio: 1,
            bookID: "sample-odisea",
            bookTitle: "La Odisea",
            customerName: "Ana",
            createdBy: .vendedor,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(3 * 86_400),
            status: .activo,
            closedAt: nil
        ),
        customerLine: "Cliente: Ana · Apartó: Vendedor",
        detailLine: "Vence en 3 días",
        accessibilitySummary: "Folio #001, La Odisea, activo",
        onDeliver: {},
        onCancel: {}
    )
    .padding()
    .background(Color.appBackground)
}
