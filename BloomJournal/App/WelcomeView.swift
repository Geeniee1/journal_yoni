import SwiftUI

struct WelcomeView: View {
    let buyMeACoffeeURL: String
    let sourceCodeURL: String
    let onStart: () -> Void
    let onOpenBuyMeACoffee: () -> Void
    let onOpenSourceCode: () -> Void

    private var sourceCodeAvailable: Bool {
        !sourceCodeURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var supportAvailable: Bool {
        !buyMeACoffeeURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            AppBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    headerSection
                    infoSection(
                        title: "How it works",
                        symbolName: "sparkles",
                        lines: [
                            "Create a connection once, then add new entries whenever something new happens.",
                            "Use Home to search and compare, New to log something quickly, Calendar to see timing, and Profile to shape the app around you."
                        ]
                    )
                    infoSection(
                        title: "Private by design",
                        symbolName: "lock.fill",
                        lines: [
                            "Everything stays local on this device.",
                            "There are no accounts, no cloud sync, and no data is shared with anyone whatsoever."
                        ]
                    )
                    infoSection(
                        title: "Free and open",
                        symbolName: "curlybraces",
                        lines: [
                            "Yoni Journal is free and has no ads.",
                            "It was built with Swift, SwiftUI, and SwiftData, and the code will be published as open source with licensing chosen to respect user privacy."
                        ]
                    )
                    supportSection
                    actionSection
                }
                .padding(.horizontal, AppTheme.Spacing.large)
                .padding(.top, AppTheme.Spacing.xLarge)
                .padding(.bottom, 160)
            }
            .scrollIndicators(.hidden)

            VStack {
                Spacer()

                Button {
                    onStart()
                } label: {
                    Label("Start Journaling", systemImage: "arrow.right.circle.fill")
                        .font(AppTheme.Typography.button)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, AppTheme.Spacing.large)
                .padding(.bottom, AppTheme.Spacing.large)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("WELCOME")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.Colors.accent)
                .tracking(1.4)

            Text("Your journal, privately.")
                .font(AppTheme.Typography.hero)
                .foregroundStyle(AppTheme.Colors.primaryText)

            Text("Yoni Journal is a private place for memory, desire, tenderness, and honesty. It helps you keep track of people, experiences, and future plans without turning your life into a spreadsheet.")
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .glassCard()
    }

    private func infoSection(title: String, symbolName: String, lines: [String]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: symbolName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.accent)
                    .frame(width: 34, height: 34)
                    .background(
                        Circle()
                            .fill(AppTheme.Colors.accentSoft.opacity(0.85))
                    )

                Text(title)
                    .font(AppTheme.Typography.sectionTitle)
                    .foregroundStyle(AppTheme.Colors.primaryText)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                ForEach(lines, id: \.self) { line in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(AppTheme.Colors.accent.opacity(0.7))
                            .frame(width: 6, height: 6)
                            .padding(.top, 7)

                        Text(line)
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(AppTheme.Colors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .glassCard()
    }

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.accent)
                    .frame(width: 34, height: 34)
                    .background(
                        Circle()
                            .fill(AppTheme.Colors.accentSoft.opacity(0.85))
                    )

                Text("Support")
                    .font(AppTheme.Typography.sectionTitle)
                    .foregroundStyle(AppTheme.Colors.primaryText)
            }

            Text("The app stays free. If you enjoy it, you can support the project with a coffee. If you are curious about how it was built, the source code link will live here too.")
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .glassCard()
    }

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            WelcomeLinkButton(
                title: "View Source",
                symbolName: "chevron.left.forwardslash.chevron.right",
                subtitle: sourceCodeAvailable ? "Open the source code repository." : "Repository link coming soon.",
                isEnabled: sourceCodeAvailable,
                action: onOpenSourceCode
            )

            WelcomeLinkButton(
                title: "Buy Me a Coffee",
                symbolName: "cup.and.saucer.fill",
                subtitle: supportAvailable ? "Support the app outside the App Store." : "Support link coming soon.",
                isEnabled: supportAvailable,
                action: onOpenBuyMeACoffee
            )
        }
    }
}

private struct WelcomeLinkButton: View {
    let title: String
    let symbolName: String
    let subtitle: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: AppTheme.Spacing.medium) {
                Image(systemName: symbolName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isEnabled ? AppTheme.Colors.accent : AppTheme.Colors.secondaryText)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(isEnabled ? AppTheme.Colors.accentSoft.opacity(0.85) : Color.white.opacity(0.28))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundStyle(isEnabled ? AppTheme.Colors.primaryText : AppTheme.Colors.secondaryText)

                    Text(subtitle)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: isEnabled ? "arrow.up.right" : "clock")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard()
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

#Preview {
    WelcomeView(
        buyMeACoffeeURL: "",
        sourceCodeURL: "",
        onStart: {},
        onOpenBuyMeACoffee: {},
        onOpenSourceCode: {}
    )
}
