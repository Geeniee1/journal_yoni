import SwiftUI
import UIKit

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

struct LotusRatingPicker: View {
    @Binding var rating: Int

    let columns = Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.small), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Text("Experience rating")
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundStyle(AppTheme.Colors.primaryText)
                Spacer()
                Text("\(rating)/10")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }

            LazyVGrid(columns: columns, spacing: AppTheme.Spacing.small) {
                ForEach(1...10, id: \.self) { level in
                    Button {
                        rating = level
                    } label: {
                        LotusRatingIcon(level: level, isSelected: level == rating)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct LotusRatingIcon: View {
    let level: Int
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isSelected ? AppTheme.Colors.accentSoft : Color.white.opacity(0.28))
                    .overlay {
                        Circle()
                            .stroke(isSelected ? AppTheme.Colors.accent : Color.white.opacity(0.42), lineWidth: isSelected ? 1.5 : 1)
                    }

                if let image = UIImage(named: "lotus-rating-\(level)") {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                } else {
                    LotusFallbackIcon(level: level)
                        .padding(12)
                }
            }
            .frame(width: 58, height: 58)

            Text("\(level)")
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .foregroundStyle(isSelected ? AppTheme.Colors.primaryText : AppTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

struct LotusRatingBadge: View {
    let rating: Int

    var body: some View {
        HStack(spacing: 8) {
            LotusRatingIcon(level: rating, isSelected: true)
                .frame(width: 44, height: 68)

            Text("\(rating)/10")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.secondaryText)
        }
    }
}

private struct LotusFallbackIcon: View {
    let level: Int

    private var petalCount: Int {
        switch level {
        case 1...2: 1
        case 3...4: 3
        case 5...6: 5
        case 7...8: 7
        default: 9
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let petalSize = size * 0.26
            let radius = size * 0.2

            ZStack {
                ForEach(0..<petalCount, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.89, green: 0.78, blue: 0.91),
                                    Color(red: 0.98, green: 0.81, blue: 0.75)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: petalSize * 0.62, height: petalSize)
                        .offset(y: -radius)
                        .rotationEffect(.degrees(Double(index) * (360.0 / Double(max(petalCount, 1)))))
                }

                Circle()
                    .fill(Color(red: 0.98, green: 0.84, blue: 0.79))
                    .frame(width: size * 0.18, height: size * 0.18)
                    .opacity(level >= 9 ? 1 : 0.0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
