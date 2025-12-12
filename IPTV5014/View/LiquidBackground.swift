import SwiftUI

struct LiquidBackground: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Sfondo Base Scuro
            Color(hex: "0f0c29").ignoresSafeArea()
            
            // Sfera 1: Viola/Blu
            Circle()
                .fill(Color(hex: "302b63").opacity(0.6))
                .frame(width: 350, height: 350)
                .blur(radius: 60)
                .offset(x: animate ? -100 : 100, y: animate ? -100 : 100)
                .animation(.easeInOut(duration: 15).repeatForever(autoreverses: true), value: animate)
            
            // Sfera 2: Ciano/Viola
            Circle()
                .fill(Color(hex: "24243e").opacity(0.6))
                .frame(width: 400, height: 400)
                .blur(radius: 50)
                .offset(x: animate ? 150 : -150, y: animate ? 100 : -100)
                .animation(.easeInOut(duration: 20).repeatForever(autoreverses: true), value: animate)
            
            // Sfera 3: Accento Blu Elettrico
            Circle()
                .fill(Color.blue.opacity(0.4))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(x: animate ? -50 : 150, y: animate ? 150 : -150)
                .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: animate)
        }
        .onAppear {
            animate.toggle()
        }
        .ignoresSafeArea()
    }
}
