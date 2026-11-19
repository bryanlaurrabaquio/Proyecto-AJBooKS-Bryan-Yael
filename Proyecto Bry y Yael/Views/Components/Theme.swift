import SwiftUI

extension Color {
    static let appBackground = Color(hex: 0xE6D6BD)   // Fondo de las pantallas
    static let appCard = Color(hex: 0xFAF3E8)         // Tarjetas, resaltan sobre el fondo
    static let appCover = Color(hex: 0xE3D2BC)        // Fondo de las portadas
    static let appAccent = Color(hex: 0x8A4516)       // Título, año/género, botones
    static let appText = Color(hex: 0x3E2A1C)         // Textos principales
    static let appMuted = Color(hex: 0x6B5040)        // Autor, descripciones
    static let appInactive = Color(hex: 0x7A6A5B)     // Botón "Guardar" sin guardar

    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
