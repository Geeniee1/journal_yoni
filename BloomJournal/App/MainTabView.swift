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
    }
}

#Preview {
    MainTabView()
        .modelContainer(PreviewContainer.makeShared())
        .environmentObject(AppLockController())
}
