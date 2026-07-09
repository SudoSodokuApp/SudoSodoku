import SwiftUI

struct ContentView: View {
    init() {
        UINavigationBar.appearance().largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
    }

    var body: some View {
        NavigationStack {
            LandingView()
        }
        .preferredColorScheme(.dark)
        .task {
            // Let the first frame land before GameKit's first-run spin-up
            // (gamed XPC, signed-out probing) competes with it; signing in
            // is optional and silent anyway (#21).
            try? await Task.sleep(for: .seconds(1))
            GameCenterManager.shared.authenticateUser()
        }
    }
}
