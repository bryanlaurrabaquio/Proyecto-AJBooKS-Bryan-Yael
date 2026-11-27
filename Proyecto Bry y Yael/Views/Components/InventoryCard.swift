import SwiftUI

// Tarjeta de un libro del inventario con su existencia, apartados activos y disponibles.
// Si el perfil activo es la encargada, muestra los botones para ajustar la existencia.
struct InventoryCard: View {
    let row: InventoryRow
    let canAdjust: Bool
    let canDecrease: Bool
    let accessibilitySummary: String
    let onIncrease: () -> Void
    let onDecrease: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(row.item.title)
                    .font(.headline)
                    .foregroundColor(.appText)

                Text(row.item.author)
                    .font(.subheadline)
                    .foregroundColor(.appMuted)

                Text("Existencia física: \(row.summary.existence)")
                    .font(.footnote)
                    .foregroundColor(.appMuted)

                Text("Apartados activos: \(row.summary.activeReservations)")
                    .font(.footnote)
                    .foregroundColor(.appMuted)

                Text("Disponibles: \(row.summary.available)")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.appAccent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilitySummary)

            if canAdjust {
                VStack(spacing: 4) {
                    Button(action: onIncrease) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Aumentar existencia de \(row.item.title)")

                    Button(action: onDecrease) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                    }
                    .disabled(!canDecrease)
                    .accessibilityLabel("Disminuir existencia de \(row.item.title)")
                }
                .foregroundColor(.appAccent)
            }
        }
        .padding(10)
        .background(Color.appCard)
        .cornerRadius(10)
    }
}
