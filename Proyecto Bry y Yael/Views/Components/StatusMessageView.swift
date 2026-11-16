import SwiftUI

// Mensaje centrado para los estados de carga, vacío, sin resultados y error.
struct StatusMessageView: View {
    let systemImage: String
    let title: String
    var message: String? = nil
    var tint: Color = Palette.accent
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.largeTitle)
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .foregroundStyle(Palette.ink)

                if let message {
                    Text(message)
                        .font(.body)
                        .foregroundStyle(Palette.inkSecondary)
                }
            }
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
    }
}
