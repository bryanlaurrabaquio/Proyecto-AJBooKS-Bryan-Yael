import Foundation

// Perfiles del local en el piloto de apartados.
// No hay inicio de sesión: el perfil se elige en la app (ver docs/modulo-apartados.md).
nonisolated enum UserRole: String, CaseIterable, Identifiable {
    case vendedor
    case encargada

    var id: String { rawValue }

    var title: String {
        switch self {
        case .vendedor:
            return "Vendedor"
        case .encargada:
            return "Encargada"
        }
    }

    // Regla de permisos: solo la encargada corrige la existencia física.
    var canAdjustStock: Bool {
        self == .encargada
    }
}
