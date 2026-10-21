import SwiftUI

// Subvista del campo de búsqueda.
// @Binding: lee y escribe el texto del padre, sin guardar uno propio.
struct SearchField: View {
    @Binding var text: String

    var body: some View {
        TextField("Buscar libro", text: $text)
            .padding(10)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
    }
}
