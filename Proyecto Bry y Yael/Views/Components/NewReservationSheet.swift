import SwiftUI

// Hoja para apartar un libro: pide el nombre del cliente y crea el folio.
// La vista no decide si hay stock: BookStockViewModel pregunta a ReservationStore y devuelve el motivo.
struct NewReservationSheet: View {
    let viewModel: BookStockViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var customerName = ""
    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(viewModel.book.title)
                        .font(.headline)

                    Text(viewModel.availabilityText)
                        .foregroundColor(.appMuted)
                }

                Section("Cliente") {
                    TextField("Nombre del cliente", text: $customerName)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .focused($isNameFocused)
                        .accessibilityIdentifier("campoCliente")
                }

                if let message = viewModel.reserveErrorMessage {
                    Section {
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.appAccent)
                    }
                }

                Section {
                    Text("El apartado vence a los \(viewModel.expirationDays) días. Si no se entrega antes, el ejemplar vuelve a estar disponible.")
                        .font(.footnote)
                        .foregroundColor(.appMuted)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Apartar libro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apartar") {
                        if viewModel.reserve(customerName: customerName) != nil {
                            dismiss()
                        }
                    }
                    .accessibilityIdentifier("botonConfirmarApartado")
                }
            }
            .onAppear {
                viewModel.clearReserveError()
                isNameFocused = true
            }
        }
        .presentationDetents([.medium, .large])
    }
}
