import SwiftUI

// Subvista del campo de búsqueda.
// @Binding: lee y escribe el texto del padre, sin guardar uno propio.
struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Palette.inkSecondary)
                .accessibilityHidden(true)

            TextField(
                "Buscar libro",
                text: $text,
                prompt: Text("Buscar por título o autor").foregroundStyle(Palette.inkSecondary)
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .foregroundStyle(Palette.ink)
            .accessibilityIdentifier("campoBusqueda")

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Palette.inkSecondary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Borrar búsqueda")
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, text.isEmpty ? 14 : 0)
        .frame(minHeight: 48)
        .background(
            RoundedRectangle(cornerRadius: Metrics.controlCornerRadius, style: .continuous)
                .fill(Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.controlCornerRadius, style: .continuous)
                .strokeBorder(Palette.border, lineWidth: 1)
        )
    }
}
