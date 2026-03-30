import SwiftUI

enum AppTab: Hashable {
    case home
    case newEntry
    case achievements
    case profile
    case settings
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(AppTab.home)

            NavigationStack {
                EntryEditorView()
            }
            .tabItem {
                Label("New Entry", systemImage: "plus.circle.fill")
            }
            .tag(AppTab.newEntry)

            NavigationStack {
                AchievementsView()
            }
            .tabItem {
                Label("Achievements", systemImage: "sparkles.rectangle.stack")
            }
            .tag(AppTab.achievements)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(AppTab.profile)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "slider.horizontal.3")
            }
            .tag(AppTab.settings)
        }
        .tint(AppTheme.Colors.accent)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            FloatingTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 18)
                .padding(.bottom, 8)
        }
    }
}

private struct FloatingTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 10) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 15, weight: .semibold))
                        Text(tab.shortTitle)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(selectedTab == tab ? .white : AppTheme.Colors.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Capsule(style: .continuous)
                            .fill(
                                selectedTab == tab
                                    ? AnyShapeStyle(
                                        LinearGradient(
                                            colors: [AppTheme.Colors.accent, AppTheme.Colors.accentBright],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    : AnyShapeStyle(Color.clear)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.40), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.14), radius: 18, x: 0, y: 12)
    }
}

extension AppTab: CaseIterable {
    static var allCases: [AppTab] {
        [.home, .newEntry, .achievements, .profile, .settings]
    }

    var shortTitle: String {
        switch self {
        case .home: "Home"
        case .newEntry: "New"
        case .achievements: "Wins"
        case .profile: "Profile"
        case .settings: "Settings"
        }
    }

    var iconName: String {
        switch self {
        case .home: "house.fill"
        case .newEntry: "plus.circle.fill"
        case .achievements: "sparkles"
        case .profile: "person.crop.circle.fill"
        case .settings: "slider.horizontal.3"
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(PreviewContainer.makeShared())
        .environmentObject(AppLockController())
}
