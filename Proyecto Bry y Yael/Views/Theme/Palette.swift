import SwiftUI

// Paleta editorial de BYbooKS.
// Los valores de modo claro y oscuro viven en Assets.xcassets (color sets "BY...");
// aquí solo se les da un nombre para que todas las vistas usen los mismos colores.
//
// Todas las combinaciones de texto y fondo que usa la app cumplen el contraste WCAG AA
// (mínimo 4.5:1) en ambos modos; ver docs/ARCHITECTURE.md.
enum Palette {
    // Fondo de las pantallas (papel cálido / negro cálido).
    static let paper = Color("BYPaper")
    // Fondo de las tarjetas.
    static let surface = Color("BYSurface")
    // Fondo de campos, etiquetas y portadas de respaldo.
    static let surfaceMuted = Color("BYSurfaceMuted")
    // Texto principal.
    static let ink = Color("BYInk")
    // Texto secundario (autor, notas).
    static let inkSecondary = Color("BYInkSecondary")
    // Color de marca (vino): nombre de la app, favoritos y botones principales.
    static let accent = Color("BYAccent")
    // Texto sobre el color de marca.
    static let onAccent = Color("BYOnAccent")
    // Acento secundario (verde azulado): año y género.
    static let teal = Color("BYTeal")
    // Bordes de tarjetas y campos.
    static let border = Color("BYBorder")
    // Mensajes de error.
    static let error = Color("BYError")

    // Nombres de los color sets (las pruebas comprueban que existan en el catálogo).
    static let assetNames = [
        "BYPaper", "BYSurface", "BYSurfaceMuted", "BYInk", "BYInkSecondary",
        "BYAccent", "BYOnAccent", "BYTeal", "BYBorder", "BYError"
    ]
}

// Medidas compartidas para que todas las pantallas tengan el mismo ritmo visual.
enum Metrics {
    static let screenPadding: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 14
    static let cardCornerRadius: CGFloat = 20
    static let controlCornerRadius: CGFloat = 14
    // En iPad el contenido no se estira más allá de este ancho.
    static let maxContentWidth: CGFloat = 720
}

// Botón principal: texto claro sobre el color de marca.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Palette.onAccent)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(Capsule().fill(Palette.accent))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

// Botón secundario: texto de marca sobre fondo neutro.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Palette.accent)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(minHeight: 44)
            .background(Capsule().fill(Palette.surface))
            .overlay(Capsule().strokeBorder(Palette.accent.opacity(0.6), lineWidth: 1))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

// Fondo de tarjeta: esquinas redondeadas, borde fino y sombra discreta.
struct CardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: Metrics.cardCornerRadius, style: .continuous)
            .fill(Palette.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Metrics.cardCornerRadius, style: .continuous)
                    .strokeBorder(Palette.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}
