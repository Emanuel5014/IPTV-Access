import SwiftUI
import Combine // <--- AGGIUNGI QUESTO IMPORT

enum AppLanguage: String, CaseIterable {
    case it = "🇮🇹 IT"
    case en = "🇺🇸 EN"
}

// Le chiavi per ogni frase dell'app
enum LangKey {
    // Login
    case appTitle, editPlaylist, listName, url, username, password, mac, cancel, login, update, yourLists, noLists
    case xtream, stalker, m3u
    
    // Home / Categorie
    case welcome, goodMorning, goodAfternoon, goodEvening, searchCat, noCat, loading
    case logout
    
    // Canali
    case searchCh, noCh, channels
    
    // Player
    case errorTitle, errorMsg, close, connecting, buffering, streamInfo, playingNow, resolution, bitrate, dataRead, lostFrames
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @AppStorage("selectedLanguage") private var languageRaw = AppLanguage.it.rawValue
    
    var currentLanguage: AppLanguage {
        get { AppLanguage(rawValue: languageRaw) ?? .it }
        set {
            languageRaw = newValue.rawValue
            objectWillChange.send() // Ora funziona grazie a 'import Combine'
        }
    }
    
    // Dizionario delle Traduzioni
    private let translations: [LangKey: [AppLanguage: String]] = [
        // LOGIN
        .appTitle: [.it: "IPTV Access", .en: "IPTV Access"],
        .editPlaylist: [.it: "Modifica Playlist", .en: "Edit Playlist"],
        .listName: [.it: "Nome Lista (es. Sport)", .en: "Playlist Name (e.g. Sport)"],
        .url: [.it: "Server URL", .en: "Server URL"],
        .username: [.it: "Username", .en: "Username"],
        .password: [.it: "Password", .en: "Password"],
        .mac: [.it: "MAC Address", .en: "MAC Address"],
        .cancel: [.it: "Annulla", .en: "Cancel"],
        .login: [.it: "ENTRA & SALVA", .en: "LOGIN & SAVE"],
        .update: [.it: "AGGIORNA", .en: "UPDATE"],
        .yourLists: [.it: "Le tue Playlist", .en: "Your Playlists"],
        .noLists: [.it: "Nessuna lista salvata", .en: "No saved playlists"],
        .xtream: [.it: "Xtream", .en: "Xtream"],
        .stalker: [.it: "Stalker", .en: "Stalker"],
        .m3u: [.it: "M3U", .en: "M3U"],
        
        // HOME
        .welcome: [.it: "Bentornato", .en: "Welcome Back"],
        .goodMorning: [.it: "Buongiorno", .en: "Good Morning"],
        .goodAfternoon: [.it: "Buon Pomeriggio", .en: "Good Afternoon"],
        .goodEvening: [.it: "Buonasera", .en: "Good Evening"],
        .searchCat: [.it: "Cerca categoria...", .en: "Search category..."],
        .noCat: [.it: "Nessuna categoria trovata", .en: "No categories found"],
        .loading: [.it: "Caricamento Portale...", .en: "Loading Portal..."],
        .logout: [.it: "Esci", .en: "Logout"],
        
        // CANALI
        .searchCh: [.it: "Cerca canale...", .en: "Search channel..."],
        .noCh: [.it: "Nessun canale trovato", .en: "No channels found"],
        .channels: [.it: "Canali", .en: "Channels"],
        
        // PLAYER
        .errorTitle: [.it: "Errore Link", .en: "Link Error"],
        .errorMsg: [.it: "Impossibile ottenere il link.", .en: "Unable to resolve link."],
        .close: [.it: "Chiudi", .en: "Close"],
        .connecting: [.it: "Connessione al server...", .en: "Connecting to server..."],
        .buffering: [.it: "Buffering...", .en: "Buffering..."],
        .streamInfo: [.it: "STREAM INFO", .en: "STREAM INFO"],
        .playingNow: [.it: "In riproduzione", .en: "Now Playing"],
        .resolution: [.it: "Risoluzione", .en: "Resolution"],
        .bitrate: [.it: "Bitrate", .en: "Bitrate"],
        .dataRead: [.it: "Dati", .en: "Data"],
        .lostFrames: [.it: "Persi", .en: "Lost"]
    ]
    
    func string(_ key: LangKey) -> String {
        return translations[key]?[currentLanguage] ?? "???"
    }
}
