import SwiftUI

struct SplashView: View {
    @State private var startAnimation = false
    @Binding var isActive: Bool // Serve per dire all'App "ho finito, chiudimi"
    
    var body: some View {
        ZStack {
            // 1. SFONDO (Usiamo lo stesso LiquidBackground per continuità)
            LiquidBackground()
            
            // 2. CONTENUTO CENTRALE
            VStack(spacing: 20) {
                // ICONA ANIMATA
                ZStack {
                    // Alone luminoso dietro
                    Circle()
                        .fill(Color.blue.opacity(0.4))
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)
                        .scaleEffect(startAnimation ? 1.2 : 0.8)
                    
                    // Icona App
                    Image(systemName: "tv.and.mediabox")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .blue.opacity(0.5), radius: 10, x: 0, y: 0)
                }
                .scaleEffect(startAnimation ? 1.0 : 0.5) // Zoom in iniziale
                .opacity(startAnimation ? 1 : 0) // Fade in
                
                // NOME APP
                Text("IPTV Access")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(startAnimation ? 1 : 0)
                    .offset(y: startAnimation ? 0 : 20) // Sale dal basso
            }
        }
        .onAppear {
            // SEQUENZA ANIMAZIONE
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                startAnimation = true
            }
            
            // ATTESA E CHIUSURA
            // Qui simuliamo un caricamento di 2.5 secondi
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isActive = false // Passa il controllo al ContentView
                }
            }
        }
    }
}
