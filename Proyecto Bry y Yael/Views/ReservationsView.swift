import SwiftUI

// Pestaña "Apartados": folios del local e inventario, con el perfil activo en la barra.
// La vista solo dibuja y avisa de los toques; las reglas viven en ReservationStore
// y los textos los prepara cada ViewModel.
struct ReservationsView: View {
    @State private var viewModel: ReservationsViewModel
    @State private var inventoryViewModel: InventoryViewModel
    @State private var panel: ReservationsPanel = .folios
    // Folio que espera confirmación (entregar y cancelar no se pueden deshacer).
    @State private var pendingAction: PendingFolioAction?

    private let profile: ProfileStore

    @Environment(\.scenePhase) private var scenePhase

    init(reservations: ReservationStore, profile: ProfileStore) {
        self.profile = profile
        _viewModel = State(
            initialValue: ReservationsViewModel(reservations: reservations, profile: profile)
        )
        _inventoryViewModel = State(
            initialValue: InventoryViewModel(reservations: reservations, profile: profile)
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Sección", selection: $panel) {
                    ForEach(ReservationsPanel.allCases) { panel in
                        Text(panel.title).tag(panel)
                    }
                }
                .pickerStyle(.segmented)

                switch panel {
                case .folios:
                    folios
                case .inventory:
                    inventory
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Apartados")
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileMenu(profile: profile)
                }
            }
            // Al abrir la pantalla y al volver a la app se marcan los folios vencidos.
            .task {
                viewModel.refresh()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    viewModel.refresh()
                }
            }
            .confirmationDialog(
                "Confirmar",
                isPresented: pendingActionBinding,
                titleVisibility: .hidden,
                presenting: pendingAction
            ) { action in
                switch action.kind {
                case .deliver:
                    Button("Entregar y bajar 1 unidad") {
                        viewModel.deliver(action.reservation)
                    }
                case .cancel:
                    Button("Cancelar folio", role: .destructive) {
                        viewModel.cancel(action.reservation)
                    }
                }

                Button("Volver", role: .cancel) {}
            } message: { action in
                Text(action.message)
            }
        }
    }

    // MARK: - Folios

    private var folios: some View {
        Group {
            if viewModel.isEmpty {
                emptyMessage(
                    systemImage: "bookmark",
                    title: "Aún no hay apartados",
                    detail: "Abre un libro en la pestaña Libros y toca Apartar. Solo se puede apartar un libro que tenga existencia en el inventario."
                )
            } else {
                List {
                    if !viewModel.activeFolios.isEmpty {
                        Section {
                            ForEach(viewModel.activeFolios) { reservation in
                                folioRow(reservation)
                            }
                        } header: {
                            Text("Activos (\(viewModel.activeFolios.count))")
                        }
                    }

                    if !viewModel.closedFolios.isEmpty {
                        Section {
                            ForEach(viewModel.closedFolios) { reservation in
                                folioRow(reservation)
                            }
                        } header: {
                            Text("Cerrados")
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .alert("No se pudo completar", isPresented: foliosErrorBinding) {
            Button("Entendido", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func folioRow(_ reservation: Reservation) -> some View {
        ReservationRow(
            reservation: reservation,
            customerLine: viewModel.customerLine(for: reservation),
            detailLine: viewModel.detailLine(for: reservation),
            accessibilitySummary: viewModel.accessibilitySummary(for: reservation),
            onDeliver: {
                pendingAction = PendingFolioAction(reservation: reservation, kind: .deliver)
            },
            onCancel: {
                pendingAction = PendingFolioAction(reservation: reservation, kind: .cancel)
            }
        )
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
    }

    // MARK: - Inventario

    private var inventory: some View {
        Group {
            if inventoryViewModel.isEmpty {
                emptyMessage(
                    systemImage: "shippingbox",
                    title: "El inventario está vacío",
                    detail: "La encargada registra las existencias desde el detalle de cada libro, en la pestaña Libros."
                )
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(inventoryViewModel.roleNote)
                        .font(.footnote)
                        .foregroundColor(.appMuted)

                    List(inventoryViewModel.rows) { row in
                        InventoryCard(
                            row: row,
                            canAdjust: inventoryViewModel.canAdjustStock,
                            canDecrease: inventoryViewModel.canDecrease(row),
                            accessibilitySummary: inventoryViewModel.accessibilitySummary(for: row),
                            onIncrease: { inventoryViewModel.increase(row) },
                            onDecrease: { inventoryViewModel.decrease(row) }
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .alert("No se pudo completar", isPresented: inventoryErrorBinding) {
            Button("Entendido", role: .cancel) {
                inventoryViewModel.clearError()
            }
        } message: {
            Text(inventoryViewModel.errorMessage ?? "")
        }
    }

    // MARK: - Apoyos

    private func emptyMessage(systemImage: String, title: String, detail: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundColor(.appAccent)
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)
                .foregroundColor(.appText)

            Text(detail)
                .multilineTextAlignment(.center)
                .foregroundColor(.appMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
        .accessibilityElement(children: .combine)
    }

    private var pendingActionBinding: Binding<Bool> {
        Binding(
            get: { pendingAction != nil },
            set: { isPresented in
                if !isPresented {
                    pendingAction = nil
                }
            }
        )
    }

    private var foliosErrorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearError()
                }
            }
        )
    }

    private var inventoryErrorBinding: Binding<Bool> {
        Binding(
            get: { inventoryViewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    inventoryViewModel.clearError()
                }
            }
        )
    }
}

private enum ReservationsPanel: String, CaseIterable, Identifiable {
    case folios
    case inventory

    var id: String { rawValue }

    var title: String {
        switch self {
        case .folios:
            return "Folios"
        case .inventory:
            return "Inventario"
        }
    }
}

// Acción sobre un folio que espera confirmación.
private struct PendingFolioAction: Identifiable {
    enum Kind {
        case deliver
        case cancel
    }

    let reservation: Reservation
    let kind: Kind

    var id: String {
        "\(reservation.folio)-\(kind)"
    }

    var message: String {
        switch kind {
        case .deliver:
            return "Se cierra el folio \(reservation.folioLabel) y baja 1 unidad de \(reservation.bookTitle). No se puede deshacer."
        case .cancel:
            return "El folio \(reservation.folioLabel) se cancela y el ejemplar de \(reservation.bookTitle) vuelve a estar disponible."
        }
    }
}

#if DEBUG
#Preview {
    ReservationsView(reservations: ReservationStore(), profile: ProfileStore())
}
#endif
