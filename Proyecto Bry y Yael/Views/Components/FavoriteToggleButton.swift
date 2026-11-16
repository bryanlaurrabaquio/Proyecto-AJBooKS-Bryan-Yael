import SwiftUI

// Botón circular para guardar o quitar un libro de favoritos desde la tarjeta.
// Área táctil de 44 x 44 puntos (mínimo recomendado por Apple).
struct FavoriteToggleButton: View {
    let isFavorite: Bool
    let bookTitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.body.weight(.semibold))
                .foregroundStyle(isFavorite ? Palette.onAccent : Palette.accent)
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 44, height: 44)
                .background(
                    Circle().fill(isFavorite ? Palette.accent : Palette.surfaceMuted)
                )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isFavorite)
        .accessibilityLabel(isFavorite ? "Quitar \(bookTitle) de favoritos" : "Guardar \(bookTitle) en favoritos")
        .accessibilityAddTraits(isFavorite ? .isSelected : [])
    }
}
