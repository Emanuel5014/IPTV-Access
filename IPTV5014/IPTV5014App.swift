import SwiftUI

@main
struct IPTV5014App: App {
    // Stato per gestire se la Splash è ancora attiva
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // 1. IL CONTENUTO VERO (ContentView)
                // Lo mettiamo sotto, così quando la splash sparisce lui è già lì pronto
                ContentView()
                
                // 2. LA SPLASH SCREEN (Sopra tutto)
                if showSplash {
                    SplashView(isActive: $showSplash)
                        .transition(.opacity) // Svanisce in dissolvenza
                        .zIndex(1) // Si assicura che stia sopra
                }
            }
            .preferredColorScheme(.dark) // Forza Dark Mode globale
        }
    }
}
