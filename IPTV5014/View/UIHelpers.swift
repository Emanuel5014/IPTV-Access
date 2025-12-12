import SwiftUI

// 1. Modificatore "Super Glass"
struct SuperGlassModifier: ViewModifier {
    var cornerRadius: CGFloat
    var opacity: CGFloat = 0.6
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial.opacity(opacity))
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 10)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .white.opacity(0.1), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
    }
}

// 2. Estensione per l'uso rapido
extension View {
    // La funzione si aspetta 'radius' e 'opacity'
    func superGlass(radius: CGFloat = 20, opacity: CGFloat = 0.8) -> some View {
        self.modifier(SuperGlassModifier(cornerRadius: radius, opacity: opacity))
    }
}

// 3. Estensione Colori HEX
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}


// --- ESTENSIONE PER CHIUDERE TASTIERA ---
extension View {
    // Funzione helper da chiamare dentro i bottoni o azioni
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // Modificatore da applicare alle viste principali
    // Quando tocchi lo sfondo, chiude la tastiera
    func onTapToDismissKeyboard() -> some View {
        self.onTapGesture {
            hideKeyboard()
        }
    }
}
