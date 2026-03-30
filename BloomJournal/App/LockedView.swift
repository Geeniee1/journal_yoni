import SwiftUI

struct LockedView: View {
    let isBiometricEnabled: Bool
    let errorMessage: String?
    let unlockAction: () async -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Spacer()

            VStack(spacing: AppTheme.Spacing.large) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.accentSoft.opacity(0.92))
                        .frame(width: 126, height: 126)

                    Image(systemName: isBiometricEnabled ? "faceid" : "lock.fill")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.plum)
                }

                VStack(spacing: AppTheme.Spacing.small) {
                    Text("Private by default.")
                        .font(AppTheme.Typography.hero)
                        .foregroundStyle(AppTheme.Colors.primaryText)
                        .multilineTextAlignment(.center)

                    Text("Bloom keeps your journal local to this device and opens only after a quick privacy check when app lock is enabled.")
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 340)
                }
            }
            .glassCard()
            .padding(.horizontal, AppTheme.Spacing.large)

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
                Label(isBiometricEnabled ? "Unlock Bloom" : "Continue", systemImage: "arrow.right.circle.fill")
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
