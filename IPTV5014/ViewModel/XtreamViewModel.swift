import Foundation
import Combine

class XtreamViewModel: ObservableObject {
    
    // --- DATI CONDIVISI (State) ---
    @Published var categories: [IPTVCategory] = []
    @Published var channels: [IPTVChannel] = []
    @Published var errorMessage: String?
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    
    // --- CREDENZIALI ---
    var serverUrl: String = ""
    var username: String = ""
    var password: String = ""
    var macAddress: String = ""
    var currentMode: PlaylistType = .xtream
    
    // --- CACHE LOCALE ---
    var allStalkerChannels: [IPTVChannel] = []
    var allM3UChannels: [IPTVChannel] = []

    // --- LOGOUT ---
    func logout() {
        DispatchQueue.main.async {
            self.isLoggedIn = false
            self.categories = []
            self.channels = []
            self.allM3UChannels = []
            self.allStalkerChannels = []
            self.serverUrl = ""
            self.username = ""
            self.password = ""
            self.macAddress = ""
        }
    }
    
    // --- LOGIN ROUTER ---
    func login(url: String, user: String = "", pass: String = "", mac: String = "", forcedMode: PlaylistType? = nil) {
        self.serverUrl = sanitizeUrl(url)
        
        // Determiniamo la modalità
        if let mode = forcedMode {
            self.currentMode = mode
        } else if !mac.isEmpty {
            self.currentMode = .stalker
        } else if url.lowercased().hasSuffix(".m3u") || url.lowercased().hasSuffix(".m3u8") {
            self.currentMode = .m3u
        } else {
            self.currentMode = .xtream
        }
        
        // Smistamento ai file specifici
        switch currentMode {
        case .xtream:
            self.username = user
            self.password = pass
            loginXtream() // Definita in +Xtream.swift
            
        case .stalker:
            self.macAddress = mac.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            attemptStalkerConnection(baseUrl: self.serverUrl) // Definita in +Stalker.swift
            
        case .m3u:
            loginM3U() // Definita in +M3U.swift
        }
    }
    
    // --- FETCH CHANNELS ROUTER ---
    func fetchChannels(categoryId: String) {
        switch currentMode {
        case .xtream:
            fetchChannelsXtream(categoryId: categoryId)
        case .stalker:
            fetchChannelsStalker(categoryId: categoryId)
        case .m3u:
            fetchChannelsM3U(categoryId: categoryId)
        }
    }
    
    // --- GET STREAM ROUTER ---
    func getStreamUrl(streamId: Int) -> URL? {
        switch currentMode {
        case .xtream:
            return URL(string: "\(serverUrl)/live/\(username)/\(password)/\(streamId).ts")
        case .stalker:
            return URL(string: "\(serverUrl)/\(streamId)")
        case .m3u:
            if let channel = allM3UChannels.first(where: { $0.streamId == streamId }),
               let vUrl = channel.videoUrl {
                return URL(string: vUrl)
            }
            return nil
        }
    }
    
    // --- HELPER CONDIVISO ---
    func sanitizeUrl(_ url: String) -> String {
        var clean = url.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if !clean.hasPrefix("http") { clean = "http://\(clean)" }
        if !clean.hasSuffix(".m3u") && !clean.hasSuffix(".m3u8") && clean.hasSuffix("/") {
            clean.removeLast()
        }
        return clean
    }
}
