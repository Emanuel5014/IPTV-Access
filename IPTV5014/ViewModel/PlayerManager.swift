import SwiftUI
import Combine // <--- QUESTA ERA LA MANCANTE!

class PlayerManager: ObservableObject {
    static let shared = PlayerManager()
    
    @Published var showPlayer = false
    @Published var isMinimized = false
    
    // Dati del canale corrente
    @Published var currentUrl: URL?
    @Published var currentChannelName: String = ""
    
    // Funzione per avviare un canale
    func play(url: URL, name: String) {
        self.currentUrl = url
        self.currentChannelName = name
        
        // Reset stato
        self.isMinimized = false
        
        // Animazione apertura
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            self.showPlayer = true
        }
    }
    
    // Chiudi tutto
    func close() {
        withAnimation {
            self.showPlayer = false
            self.currentUrl = nil // Ferma il player
        }
    }
}
