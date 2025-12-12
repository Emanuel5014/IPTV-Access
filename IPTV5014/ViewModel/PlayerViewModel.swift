import Foundation
import MobileVLCKit
import Combine

// Modello Dati
struct StreamStats {
    var resolution: String = "-- x --"
    var bitrate: String = "--"
    var lostFrames: Int = 0
    var readBytes: String = "--"
    var audioCodec: String = ""
    var videoCodec: String = ""
}

class PlayerViewModel: NSObject, ObservableObject {
    
    let mediaPlayer = VLCMediaPlayer()
    
    @Published var isPlaying: Bool = true
    @Published var volume: Float = 1.0
    @Published var timeString: String = "00:00"
    @Published var isBuffering: Bool = false
    @Published var stats = StreamStats()
    
    // --- NUOVO: Stato Riconnessione (per mostrare eventuali avvisi UI) ---
    @Published var isReconnecting: Bool = false
    
    private var statsTimer: Timer?
    private var lastReadBytes: Int = 0
    
    // --- LOGICA AUTO-RECONNECT ---
    private var isUserPaused: Bool = false // Capisce se lo stop è voluto dall'utente
    private var retryCount: Int = 0        // Contatore tentativi attuali
    private let maxRetries: Int = 5        // Numero massimo di tentativi
    
    func setupPlayer(url: URL, view: UIView) {
        let media = VLCMedia(url: url)
        
        media.delegate = self
        
        // Opzioni VLC ottimizzate per lo streaming
        media.addOptions([
            "network-caching": 1500,
            "clock-jitter": 0,
            "clock-synchro": 0,
            "stats": 1, // Abilita le statistiche
            "http-reconnect": 1 // Aiuta VLC a riconnettersi nativamente
        ])
        
        mediaPlayer.media = media
        mediaPlayer.drawable = view
        mediaPlayer.delegate = self
        
        // Reset dei contatori all'avvio di un nuovo video
        retryCount = 0
        isUserPaused = false
        isReconnecting = false
        
        mediaPlayer.play()
        
        media.parse(options: VLCMediaParsingOptions(rawValue: 1))
        
        lastReadBytes = 0
        startStatsTimer()
    }
    
    func startStatsTimer() {
        statsTimer?.invalidate()
        statsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }
    
    func updateStats() {
            guard let media = mediaPlayer.media else { return }
            
            let width = mediaPlayer.videoSize.width
            let height = mediaPlayer.videoSize.height
            let resString = (width > 0 && height > 0) ? "\(Int(width)) x \(Int(height))" : "Buffering..."
            
            var vCodec = "-"
            var aCodec = "-"
            
            if let tracks = media.tracksInformation as? [[String: Any]] {
                for track in tracks {
                    if let type = track[VLCMediaTracksInformationType] as? String {
                        if type == VLCMediaTracksInformationTypeVideo, let codec = track[VLCMediaTracksInformationCodec] as? String {
                            vCodec = codec.stringByDecodingHTMLEntities
                        } else if type == VLCMediaTracksInformationTypeAudio, let codec = track[VLCMediaTracksInformationCodec] as? String {
                            aCodec = codec.stringByDecodingHTMLEntities
                        }
                    }
                }
            }
            
            var currentReadBytes: Int = 0
            var lost = 0
            var bitrateKbps = 0
            
            // --- CORREZIONE QUI ---
            // Rimosso "if let", accediamo direttamente perché non è opzionale
            let s = media.statistics
            
            currentReadBytes = Int(s.readBytes)
            lost = Int(s.lostPictures)
            
            if s.demuxBitrate > 0 {
                bitrateKbps = Int(s.demuxBitrate * 8 / 1000)
            } else {
                if lastReadBytes > 0 && currentReadBytes > lastReadBytes {
                    let diff = currentReadBytes - lastReadBytes
                    bitrateKbps = Int(Double(diff) * 8 / 1000)
                }
            }
            // ----------------------
            
            lastReadBytes = currentReadBytes
            
            let dataAvailable = currentReadBytes > 0
            let finalBitrate = dataAvailable ? "\(bitrateKbps) kb/s" : "Live"
            let finalRead = dataAvailable ? String(format: "%.1f MB", Double(currentReadBytes) / 1024 / 1024) : "--"
            
            DispatchQueue.main.async {
                self.stats.resolution = resString
                self.stats.bitrate = finalBitrate
                self.stats.readBytes = finalRead
                self.stats.lostFrames = lost
                self.stats.videoCodec = vCodec
                self.stats.audioCodec = aCodec
            }
        }
    
    // --- GESTIONE PLAY/PAUSA UTENTE ---
    // È fondamentale distinguere se l'utente mette pausa o se cade la linea
    
    func togglePlayPause() {
        if mediaPlayer.isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func play() {
        isUserPaused = false // L'utente vuole vedere, resettiamo il flag
        retryCount = 0       // Resettiamo i tentativi se l'utente preme play manualmente
        mediaPlayer.play()
        isPlaying = true
    }
    
    func pause() {
        isUserPaused = true  // L'utente ha messo pausa intenzionalmente
        mediaPlayer.pause()
        isPlaying = false
    }
    
    func setVolume(_ value: Float) {
        mediaPlayer.audio?.volume = Int32(value * 100)
        self.volume = value
    }
    
    func stop() {
        isUserPaused = true // Stop definitivo
        statsTimer?.invalidate()
        mediaPlayer.stop()
    }
}

// Delegate VLC
extension PlayerViewModel: VLCMediaPlayerDelegate, VLCMediaDelegate {
    
    func mediaPlayerStateChanged(_ aNotification: Notification) {
        DispatchQueue.main.async {
            switch self.mediaPlayer.state {
                
            case .buffering:
                self.isBuffering = true
                self.isReconnecting = false
                
            case .playing:
                self.isBuffering = false
                self.isPlaying = true
                self.isReconnecting = false
                self.retryCount = 0 // Connessione riuscita! Resettiamo i tentativi.
                
            case .error, .ended, .stopped:
                self.isBuffering = false
                self.isPlaying = false
                
                // --- LOGICA DI RICONNESSIONE ---
                // Se NON è stato l'utente a fermare il video
                // E non abbiamo superato i tentativi massimi (5)
                if !self.isUserPaused && self.retryCount < self.maxRetries {
                    self.isReconnecting = true
                    self.retryCount += 1
                    print("⚠️ Stream interrotto. Tentativo di riconnessione \(self.retryCount)/\(self.maxRetries)...")
                    
                    // Aspettiamo 1.5 secondi e riproviamo
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        // Controlliamo di nuovo che l'utente non abbia chiuso il player nel frattempo
                        if !self.isUserPaused {
                            self.mediaPlayer.stop() // Reset pulito
                            self.mediaPlayer.play() // Riprova
                        }
                    }
                } else if self.retryCount >= self.maxRetries {
                    print("❌ Troppi tentativi falliti. Rinuncio.")
                    self.isReconnecting = false
                }
                
            default: break
            }
        }
    }
    
    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        DispatchQueue.main.async {
            self.timeString = self.mediaPlayer.time.stringValue
            if self.mediaPlayer.time.intValue > 0 && self.isBuffering {
                self.isBuffering = false
                self.isPlaying = true
            }
        }
    }
    
    func mediaDidFinishParsing(_ aMedia: VLCMedia) {
        // Log opzionale
    }
}

// Helper Stringhe
extension String {
    var stringByDecodingHTMLEntities: String {
        return self.replacingOccurrences(of: "\0", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
