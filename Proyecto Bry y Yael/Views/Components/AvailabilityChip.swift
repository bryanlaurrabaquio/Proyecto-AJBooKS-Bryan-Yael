import SwiftUI

// Etiqueta de disponibilidad que se muestra en la tarjeta de un libro:
// "Disponibles: 2" o "Sin stock". Si el libro no está en el inventario no muestra nada.
// Colores con contraste suficiente: texto blanco sobre appAccent (7.1:1) y sobre appInactive (5.2:1).
struct AvailabilityChip: View {
    let availability: BookAvailability

    var body: some View {
        if let text = availability.chipText {
            Label(text, systemImage: availability.canReserve ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(availability.canReserve ? Color.appAccent : Color.appInactive)
                )
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        AvailabilityChip(availability: .available(2))
        AvailabilityChip(availability: .soldOut)
        AvailabilityChip(availability: .notStocked)
    }
    .padding()
    .background(Color.appBackground)
}
