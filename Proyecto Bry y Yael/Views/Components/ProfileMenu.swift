import SwiftUI

// Menú para elegir el perfil activo del local (vendedor o encargada).
struct ProfileMenu: View {
    @Bindable var profile: ProfileStore

    var body: some View {
        Menu {
            Picker("Perfil", selection: $profile.role) {
                ForEach(UserRole.allCases) { role in
                    Text(role.title).tag(role)
                }
            }
        } label: {
            Label(profile.role.title, systemImage: "person.crop.circle")
        }
        .accessibilityLabel("Perfil activo: \(profile.role.title)")
        .accessibilityHint("Toca para cambiar de perfil")
        .accessibilityIdentifier("menuPerfil")
    }
}

#Preview {
    NavigationStack {
        Text("Contenido")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileMenu(profile: ProfileStore())
                }
            }
    }
}
