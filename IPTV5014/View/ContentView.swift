import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = XtreamViewModel()
    
    // Il nostro Player Manager
    @ObservedObject var playerManager = PlayerManager.shared

    var body: some View {
        ZStack {
            // 1. SFONDO PERSISTENTE
            LiquidBackground()
            
            // 2. CONTENUTO APP
            Group {
                if viewModel.isLoggedIn {
                    NavigationStack {
                        CategoryGridView(viewModel: viewModel)
                    }
                    .transition(.opacity.animation(.easeInOut(duration: 0.6)))
                } else {
                    LoginView(viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            
            // 3. IL PLAYER FLUTTUANTE (Sempre in cima)
            FloatingPlayerView(appViewModel: viewModel)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.isLoggedIn)
        .preferredColorScheme(.dark)
    }
}
