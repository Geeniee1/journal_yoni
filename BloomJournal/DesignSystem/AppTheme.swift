import SwiftUI

enum AppTheme {
    enum Colors {
        static let background = Color(red: 0.973, green: 0.949, blue: 0.929)
        static let backgroundDark = Color(red: 0.123, green: 0.102, blue: 0.117)
        static let card = Color.white.opacity(0.82)
        static let cardDark = Color(red: 0.176, green: 0.149, blue: 0.168)
        static let accent = Color(red: 0.734, green: 0.435, blue: 0.553)
        static let accentSoft = Color(red: 0.914, green: 0.808, blue: 0.841)
        static let primaryText = Color(red: 0.176, green: 0.141, blue: 0.157)
        static let secondaryText = Color(red: 0.412, green: 0.349, blue: 0.376)
        static let warning = Color(red: 0.760, green: 0.323, blue: 0.323)
        static let border = Color.white.opacity(0.28)
        static let shadow = Color.black.opacity(0.08)
    }

    enum Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
        static let xLarge: CGFloat = 32
    }

    enum CornerRadius {
        static let small: CGFloat = 14
        static let medium: CGFloat = 22
        static let large: CGFloat = 30
    }

    enum Typography {
        static let display = Font.system(.largeTitle, design: .serif).weight(.semibold)
        static let sectionTitle = Font.system(.title3, design: .serif).weight(.semibold)
        static let cardTitle = Font.system(.headline, design: .rounded).weight(.semibold)
        static let body = Font.system(.body, design: .rounded)
        static let caption = Font.system(.caption, design: .rounded)
        static let button = Font.system(.headline, design: .rounded).weight(.semibold)
    }
}

struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [AppTheme.Colors.backgroundDark, Color(red: 0.172, green: 0.133, blue: 0.168)]
                : [AppTheme.Colors.background, Color(red: 0.956, green: 0.906, blue: 0.878)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(AppTheme.Colors.accentSoft.opacity(colorScheme == .dark ? 0.12 : 0.28))
                .frame(width: 260, height: 260)
                .blur(radius: 16)
                .offset(x: 90, y: -60)
        }
        .ignoresSafeArea()
    }
}

struct AppPrivacyShield: View {
    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: AppTheme.Spacing.medium) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.Colors.accent)

                Text("Private view")
                    .font(AppTheme.Typography.sectionTitle)
                    .foregroundStyle(AppTheme.Colors.primaryText)
            }
        }
        .allowsHitTesting(false)
    }
}

struct GlassCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                    .fill(colorScheme == .dark ? AppTheme.Colors.cardDark : AppTheme.Colors.card)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous)
                            .stroke(AppTheme.Colors.border, lineWidth: 1)
                    }
            )
            .shadow(color: AppTheme.Colors.shadow, radius: 18, x: 0, y: 8)
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.horizontal, AppTheme.Spacing.large)
            .background(
                Capsule(style: .continuous)
                    .fill(AppTheme.Colors.accent)
                    .opacity(configuration.isPressed ? 0.8 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.smooth(duration: 0.2), value: configuration.isPressed)
    }
}
