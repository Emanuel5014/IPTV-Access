import Foundation
import SwiftUI

// Tipi di Lista
enum PlaylistType: String, Codable, CaseIterable {
    case xtream = "Xtream Codes"
    case stalker = "Stalker Portal"
    case m3u = "M3U Link"
}

struct SavedPlaylist: Codable, Identifiable {
    var id = UUID()
    let name: String
    let url: String
    let username: String?
    let password: String?
    let macAddress: String?
    let type: PlaylistType
}

class PlaylistManager {
    static let shared = PlaylistManager()
    private let key = "saved_playlists"
    
    // Carica Liste
    func loadPlaylists() -> [SavedPlaylist] {
        if let data = UserDefaults.standard.data(forKey: key),
           let playlists = try? JSONDecoder().decode([SavedPlaylist].self, from: data) {
            return playlists
        }
        return []
    }
    
    // Salva Nuova Lista
    func savePlaylist(name: String, url: String, type: PlaylistType, user: String = "", pass: String = "", mac: String = "") {
        var playlists = loadPlaylists()
        let newPlaylist = SavedPlaylist(
            name: name, url: url, username: user, password: pass, macAddress: mac, type: type
        )
        playlists.append(newPlaylist)
        saveToDisk(playlists)
    }
    
    // --- NUOVO: Aggiorna Lista Esistente ---
    func updatePlaylist(id: UUID, name: String, url: String, type: PlaylistType, user: String = "", pass: String = "", mac: String = "") {
        var playlists = loadPlaylists()
        
        // Cerchiamo l'indice della lista con questo ID
        if let index = playlists.firstIndex(where: { $0.id == id }) {
            // Creiamo la versione aggiornata mantenendo lo stesso ID
            let updatedPlaylist = SavedPlaylist(
                id: id, // Manteniamo il vecchio ID!
                name: name,
                url: url,
                username: user,
                password: pass,
                macAddress: mac,
                type: type
            )
            // Sostituiamo quella vecchia
            playlists[index] = updatedPlaylist
            saveToDisk(playlists)
        }
    }
    
    // Cancella
    func deletePlaylist(at offsets: IndexSet) {
        var playlists = loadPlaylists()
        playlists.remove(atOffsets: offsets)
        saveToDisk(playlists)
    }
    
    // Helper privato per salvare
    private func saveToDisk(_ playlists: [SavedPlaylist]) {
        if let encoded = try? JSONEncoder().encode(playlists) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}
