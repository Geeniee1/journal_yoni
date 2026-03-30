import SwiftUI

struct LockedView: View {
    let isBiometricEnabled: Bool
    let errorMessage: String?
    let unlockAction: () async -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.Colors.card)
                    .frame(width: 110, height: 110)

                Image(systemName: isBiometricEnabled ? "faceid" : "lock.fill")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.accent)
            }

            VStack(spacing: AppTheme.Spacing.small) {
                Text("Your journal stays with you.")
                    .font(AppTheme.Typography.display)
                    .foregroundStyle(AppTheme.Colors.primaryText)
                    .multilineTextAlignment(.center)

                Text("Bloom opens only after a quick privacy check when app lock is enabled.")
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.warning)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                Task {
                    await unlockAction()
                }
            } label: {
                Label(isBiometricEnabled ? "Unlock with Face ID" : "Continue", systemImage: "arrow.right.circle.fill")
                    .font(AppTheme.Typography.button)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, AppTheme.Spacing.xLarge)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppBackground())
    }
}

#Preview {
    LockedView(isBiometricEnabled: true, errorMessage: nil, unlockAction: {})
}
