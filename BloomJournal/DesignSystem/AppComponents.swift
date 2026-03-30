import SwiftUI

struct ScreenContainer<Content: View>: View {
    let title: String
    let subtitle: String?
    let eyebrow: String?
    @ViewBuilder let content: Content

    init(title: String, subtitle: String? = nil, eyebrow: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.eyebrow = eyebrow
        self.content = content()
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                        if let eyebrow {
                            Text(eyebrow.uppercased())
                                .font(.system(.caption, design: .rounded).weight(.bold))
                                .foregroundStyle(AppTheme.Colors.accent)
                                .tracking(1.4)
                        }

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                            Text(title)
                                .font(AppTheme.Typography.hero)
                                .foregroundStyle(AppTheme.Colors.primaryText)
                            if let subtitle {
                                Text(subtitle)
                                    .font(AppTheme.Typography.body)
                                    .foregroundStyle(AppTheme.Colors.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    content
                }
                .padding(.horizontal, AppTheme.Spacing.large)
                .padding(.top, AppTheme.Spacing.xLarge)
                .padding(.bottom, 150)
            }
            .scrollIndicators(.hidden)
        }
    }
}

struct EmptyStateCard: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(AppTheme.Colors.accent)
                .frame(width: 42, height: 42)
                .background(
                    Circle()
                        .fill(AppTheme.Colors.accentSoft.opacity(0.85))
                )

            Text(title)
                .font(AppTheme.Typography.cardTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text(message)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let symbolName: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Image(systemName: symbolName)
                .foregroundStyle(AppTheme.Colors.accent)
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .fill(AppTheme.Colors.accentSoft.opacity(0.85))
                )

            Text(value)
                .font(AppTheme.Typography.metric)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTheme.Typography.sectionTitle)
                .foregroundStyle(AppTheme.Colors.primaryText)
            if let subtitle {
                Text(subtitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }
        }
    }
}

struct CapsuleToggleButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded).weight(.semibold))
            .foregroundStyle(isSelected ? .white : AppTheme.Colors.primaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        isSelected
                            ? AnyShapeStyle(LinearGradient(colors: [AppTheme.Colors.accent, AppTheme.Colors.accentBright], startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(Color.white.opacity(0.48))
                    )
            )
            .overlay {
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(isSelected ? 0 : 0.55), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
