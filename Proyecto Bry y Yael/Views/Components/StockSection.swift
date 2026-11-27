import SwiftUI

// Sección "Disponibilidad en el local" del detalle de un libro.
// Toma el ReservationStore y el perfil del entorno (los inyecta RootView); si no están
// (por ejemplo, en una vista previa del detalle) la sección simplemente no aparece.
struct StockSection: View {
    let book: Book

    @Environment(ReservationStore.self) private var reservations: ReservationStore?
    @Environment(ProfileStore.self) private var profile: ProfileStore?

    var body: some View {
        if let reservations, let profile {
            StockSectionContent(book: book, reservations: reservations, profile: profile)
        }
    }
}

private struct StockSectionContent: View {
    // El ViewModel se crea una sola vez para conservar sus mensajes (igual que en ContentView).
    @State private var viewModel: BookStockViewModel
    @State private var isShowingReservationSheet = false

    init(book: Book, reservations: ReservationStore, profile: ProfileStore) {
        _viewModel = State(
            initialValue: BookStockViewModel(book: book, reservations: reservations, profile: profile)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Disponibilidad en el local")
                .font(.headline)

            Text(viewModel.availabilityText)
                .font(.title3.weight(.semibold))
                .foregroundColor(viewModel.canReserve ? .appAccent : .appMuted)

            if let breakdown = viewModel.breakdownText {
                Text(breakdown)
                    .font(.footnote)
                    .foregroundColor(.appMuted)
            }

            reserveButton

            if let confirmation = viewModel.confirmationMessage {
                Label(confirmation, systemImage: "checkmark.circle.fill")
                    .font(.footnote)
                    .foregroundColor(.appAccent)
            }

            if viewModel.canAdjustStock {
                stockAdjuster
            } else {
                Text(viewModel.roleNote)
                    .font(.footnote)
                    .foregroundColor(.appMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.appCard)
        .cornerRadius(10)
        .sheet(isPresented: $isShowingReservationSheet) {
            NewReservationSheet(viewModel: viewModel)
        }
        .alert("No se pudo completar", isPresented: adjustErrorBinding) {
            Button("Entendido", role: .cancel) {
                viewModel.clearAdjustError()
            }
        } message: {
            Text(viewModel.adjustErrorMessage ?? "")
        }
    }

    private var reserveButton: some View {
        Button {
            viewModel.clearConfirmation()
            isShowingReservationSheet = true
        } label: {
            Label("Apartar", systemImage: "bookmark.fill")
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canReserve ? Color.appAccent : Color.appInactive)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .disabled(!viewModel.canReserve)
        .accessibilityHint(
            viewModel.canReserve
            ? "Crea un folio para un cliente"
            : "No hay ejemplares disponibles para apartar"
        )
        .accessibilityIdentifier("botonApartar")
    }

    // Solo la encargada ve estos controles; ReservationStore vuelve a validar el permiso.
    private var stockAdjuster: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Existencia física")
                    .foregroundColor(.appText)

                Spacer()

                Button {
                    viewModel.adjustExistence(by: -1)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                }
                .disabled(!viewModel.canDecreaseExistence)
                .accessibilityLabel("Disminuir existencia")

                Text("\(viewModel.existence)")
                    .font(.headline)
                    .foregroundColor(.appText)
                    .frame(minWidth: 28)
                    .accessibilityLabel("Existencia \(viewModel.existence)")

                Button {
                    viewModel.adjustExistence(by: 1)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Aumentar existencia")
            }
            .foregroundColor(.appAccent)

            Text("Perfil activo: Encargada. Al subir la existencia de un libro nuevo, se registra en el inventario.")
                .font(.footnote)
                .foregroundColor(.appMuted)
        }
    }

    private var adjustErrorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.adjustErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearAdjustError()
                }
            }
        )
    }
}
