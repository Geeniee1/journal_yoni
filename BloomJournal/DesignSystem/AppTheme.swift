import SwiftUI

enum AppTheme {
    enum Colors {
        static let background = Color(red: 0.986, green: 0.958, blue: 0.939)
        static let backgroundDark = Color(red: 0.109, green: 0.090, blue: 0.109)
        static let canvas = Color(red: 0.957, green: 0.917, blue: 0.892)
        static let canvasDark = Color(red: 0.169, green: 0.129, blue: 0.153)
        static let card = Color.white.opacity(0.70)
        static let cardDark = Color(red: 0.176, green: 0.149, blue: 0.168).opacity(0.86)
        static let accent = Color(red: 0.745, green: 0.365, blue: 0.514)
        static let accentBright = Color(red: 0.890, green: 0.498, blue: 0.584)
        static let accentSoft = Color(red: 0.964, green: 0.833, blue: 0.843)
        static let plum = Color(red: 0.392, green: 0.247, blue: 0.341)
        static let gold = Color(red: 0.812, green: 0.639, blue: 0.408)
        static let primaryText = Color(red: 0.160, green: 0.121, blue: 0.145)
        static let secondaryText = Color(red: 0.396, green: 0.318, blue: 0.353)
        static let warning = Color(red: 0.760, green: 0.323, blue: 0.323)
        static let border = Color.white.opacity(0.34)
        static let borderDark = Color.white.opacity(0.08)
        static let shadow = Color.black.opacity(0.10)
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
        static let xLarge: CGFloat = 38
    }

    enum Typography {
        static let hero = Font.system(size: 40, weight: .semibold, design: .serif)
        static let display = Font.system(.largeTitle, design: .serif).weight(.semibold)
        static let sectionTitle = Font.system(.title3, design: .serif).weight(.semibold)
        static let cardTitle = Font.system(.headline, design: .rounded).weight(.semibold)
        static let body = Font.system(.body, design: .rounded)
        static let caption = Font.system(.caption, design: .rounded)
        static let button = Font.system(.headline, design: .rounded).weight(.semibold)
        static let metric = Font.system(size: 28, weight: .bold, design: .rounded)
    }
}

struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [AppTheme.Colors.backgroundDark, AppTheme.Colors.canvasDark]
                    : [AppTheme.Colors.background, AppTheme.Colors.canvas],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(AppTheme.Colors.accentSoft.opacity(colorScheme == .dark ? 0.07 : 0.45))
                .frame(width: 320, height: 320)
                .blur(radius: 24)
                .offset(x: 120, y: -160)

            Circle()
                .fill(AppTheme.Colors.accent.opacity(colorScheme == .dark ? 0.10 : 0.16))
                .frame(width: 280, height: 280)
                .blur(radius: 30)
                .offset(x: -140, y: 240)

            RoundedRectangle(cornerRadius: 90, style: .continuous)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.03 : 0.28), lineWidth: 1)
                .frame(width: 280, height: 420)
                .rotationEffect(.degrees(18))
                .offset(x: 170, y: -40)
                .blur(radius: 0.4)
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
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                            .fill(colorScheme == .dark ? AppTheme.Colors.cardDark : AppTheme.Colors.card)
                            .opacity(0.92)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                            .stroke(colorScheme == .dark ? AppTheme.Colors.borderDark : AppTheme.Colors.border, lineWidth: 1)
                    }
            )
            .shadow(color: AppTheme.Colors.shadow, radius: 24, x: 0, y: 18)
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
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.Colors.accent, AppTheme.Colors.accentBright],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(configuration.isPressed ? 0.8 : 1)
            )
            .shadow(color: AppTheme.Colors.accent.opacity(0.28), radius: 16, x: 0, y: 12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.smooth(duration: 0.2), value: configuration.isPressed)
    }
}
