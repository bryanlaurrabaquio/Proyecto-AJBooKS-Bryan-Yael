import Foundation
import Observation

// Perfil activo del local. Es estado de sesión: no se guarda en disco.
// Cada vez que se abre la app empieza como vendedor (el perfil con menos permisos).
@MainActor
@Observable
final class ProfileStore {

    var role: UserRole

    init(role: UserRole = .vendedor) {
        self.role = role
    }
}
