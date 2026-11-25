import SwiftUI

@main
struct QingTVApp: App {
    @StateObject private var store = Store()

    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(store)
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            DiscoverView()
                .tabItem { Label("发现", systemImage: "sparkles.tv") }
            LiveView()
                .tabItem { Label("直播", systemImage: "dot.radiowaves.left.and.right") }
            SettingsView()
                .tabItem { Label("设置", systemImage: "slider.horizontal.3") }
        }
        .preferredColorScheme(.dark)
    }
}
