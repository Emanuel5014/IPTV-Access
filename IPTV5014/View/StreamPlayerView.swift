import SwiftUI

struct StreamPlayerView: View {
    // Input
    let url: URL
    let channelName: String
    @ObservedObject var appViewModel: XtreamViewModel
    
    @Environment(\.dismiss) var dismiss
    @StateObject var playerVM = PlayerViewModel()
    
    // UI State
    @State private var showControls = true
    @State private var showInfoOverlay = false
    @State private var timer: Timer?
    
    // Link Resolution State
    @State private var resolvedUrl: URL?
    @State private var resolutionError: String?
    
    var body: some View {
        ZStack {
            // 1. BACKGROUND / VIDEO LAYER
            Color.black.ignoresSafeArea()
            
            if let playUrl = resolvedUrl {
                VLCPlayerView(playerViewModel: playerVM, url: playUrl)
                    .edgesIgnoringSafeArea(.all)
            } else if let error = resolutionError {
                // Errore Risoluzione
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    Text("Errore Link")
                        .font(.title3).bold().foregroundColor(.white)
                    Text(error)
                        .foregroundColor(.gray).multilineTextAlignment(.center)
                    Button("Chiudi") { dismiss() }
                        .padding().background(Color.white.opacity(0.1)).cornerRadius(10).foregroundColor(.white)
                }
            } else {
                // Loading Iniziale
                VStack(spacing: 20) {
                    ProgressView().tint(.white).scaleEffect(1.5)
                    Text("Connessione al server...").foregroundColor(.white.opacity(0.7))
                }
            }
            
            // --- FIX CRITICO: TOUCH LAYER ---
            // Questo strato invisibile cattura i tocchi al posto del player.
            // Risolve il problema del blocco interazione.
            if resolvedUrl != nil {
                Color.clear
                    .contentShape(Rectangle()) // Rende intera area cliccabile anche se trasparente
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation { showControls.toggle() }
                        resetTimer()
                    }
            }
            
            // 2. BUFFERING OVERLAY
            if playerVM.isBuffering && resolvedUrl != nil {
                ZStack {
                    Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                    VStack {
                        ProgressView().tint(.white).scaleEffect(1.5)
                        Text("Buffering...").font(.caption).foregroundColor(.white).padding(.top, 10)
                    }
                }
                .allowsHitTesting(false) // Lascia passare i click sotto
            }
            
            // 3. STATISTICHE (Info Overlay)
            if showInfoOverlay {
                infoPanel
                    .allowsHitTesting(false) // Non blocca i click
            }
            
            // 4. CONTROLLI UTENTE
            if showControls {
                controlsOverlay
                    .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            performLinkResolution()
            resetTimer()
        }
        .onDisappear { playerVM.stop() }
    }
    
    // --- COMPONENTI UI ---
    
    var controlsOverlay: some View {
        VStack {
            // BARRA SUPERIORE
            HStack {
                Button(action: { playerVM.stop(); dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3).bold()
                        .foregroundColor(.white)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                
                Spacer()
                
                VStack {
                    Text(channelName)
                        .font(.headline).foregroundColor(.white)
                        .shadow(radius: 5)
                    if playerVM.isBuffering {
                        Text("Caricamento...").font(.caption).foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Button(action: { withAnimation { showInfoOverlay.toggle() }; resetTimer() }) {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundColor(showInfoOverlay ? .green : .white)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .padding(.top, 50)
            
            Spacer()
            
            // BARRA INFERIORE (Play/Pause + Volume)
            VStack(spacing: 20) {
                // Tasto Play Gigante
                Button(action: { playerVM.togglePlayPause(); resetTimer() }) {
                    Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        .shadow(radius: 10)
                }
                
                // Slider Volume
                HStack(spacing: 15) {
                    Image(systemName: "speaker.fill").foregroundColor(.white.opacity(0.7))
                    Slider(value: Binding(get: { playerVM.volume }, set: { playerVM.setVolume($0) }), in: 0...1)
                        .accentColor(.white)
                    Image(systemName: "speaker.wave.3.fill").foregroundColor(.white.opacity(0.7))
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.horizontal, 30)
            }
            .padding(.bottom, 50)
        }
        .background(
            LinearGradient(colors: [.black.opacity(0.6), .clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }
    
    var infoPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("STREAM DEBUG").font(.caption).bold().foregroundColor(.gray)
            Divider().background(Color.gray)
            statRow("Resolution", playerVM.stats.resolution)
            statRow("Bitrate", playerVM.stats.bitrate)
            statRow("Data Read", playerVM.stats.readBytes)
            statRow("Lost Frames", "\(playerVM.stats.lostFrames)")
            statRow("Codecs", "V: \(playerVM.stats.videoCodec) / A: \(playerVM.stats.audioCodec)")
        }
        .padding()
        .frame(width: 250)
        .superGlass(radius: 15)
        .position(x: 150, y: 150)
    }
    
    func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.caption2).foregroundColor(.gray)
            Spacer()
            Text(value).font(.caption2).bold().foregroundColor(.green)
        }
    }
    
    // --- LOGICA ---
    func performLinkResolution() {
        let urlString = url.absoluteString
        if urlString.contains(".ts") || urlString.contains(".m3u8") || urlString.contains(".mp4") {
            self.resolvedUrl = url
            return
        }
        let lastPart = url.lastPathComponent
        if let streamId = Int(lastPart) {
            print("Rilevato ID Stalker: \(streamId)")
            appViewModel.resolveStalkerLink(streamId: streamId) { realLink in
                DispatchQueue.main.async {
                    if let realLink = realLink {
                        self.resolvedUrl = realLink
                    } else {
                        self.resolutionError = "Impossibile ottenere il link."
                    }
                }
            }
        } else {
            self.resolvedUrl = url
        }
    }
    
    func resetTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
            withAnimation { showControls = false }
        }
    }
}
