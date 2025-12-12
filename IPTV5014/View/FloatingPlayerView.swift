import SwiftUI

struct FloatingPlayerView: View {
    @ObservedObject var playerManager = PlayerManager.shared
    @ObservedObject var appViewModel: XtreamViewModel
    
    // --- STATO POSIZIONE ---
    @State private var miniOffset: CGSize = .zero
    @State private var dragOffset: CGSize = .zero
    
    // Dimensioni del Mini Player (16:9)
    let miniWidth: CGFloat = 300
    let miniHeight: CGFloat = 169
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                
                if playerManager.showPlayer {
                    
                    // 1. IL PLAYER
                    InnerPlayerContainer(
                        url: playerManager.currentUrl ?? URL(string: "http://dummy")!,
                        channelName: playerManager.currentChannelName,
                        appViewModel: appViewModel,
                        isMini: playerManager.isMinimized
                    )
                    // --- DIMENSIONI ---
                    .frame(
                        width: playerManager.isMinimized ? miniWidth : geo.size.width,
                        height: playerManager.isMinimized ? miniHeight : geo.size.height
                    )
                    // FULL SCREEN REALE
                    .ignoresSafeArea()
                    .statusBar(hidden: playerManager.showPlayer && !playerManager.isMinimized)
                    
                    .cornerRadius(playerManager.isMinimized ? 12 : 0)
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: playerManager.isMinimized ? 12 : 0)
                            .stroke(Color.white.opacity(0.2), lineWidth: playerManager.isMinimized ? 1 : 0)
                    )
                    
                    // --- POSIZIONAMENTO ---
                    .offset(
                        x: playerManager.isMinimized ? (miniOffset.width + dragOffset.width) : 0,
                        y: playerManager.isMinimized ? (miniOffset.height + dragOffset.height) : (dragOffset.height > 0 ? dragOffset.height : 0)
                    )
                    
                    // --- GESTURES ---
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if playerManager.isMinimized {
                                    dragOffset = value.translation
                                } else {
                                    if value.translation.height > 0 {
                                        dragOffset = value.translation
                                    }
                                }
                            }
                            .onEnded { value in
                                if playerManager.isMinimized {
                                    miniOffset.width += value.translation.width
                                    miniOffset.height += value.translation.height
                                    dragOffset = .zero
                                    snapToBounds(screenSize: geo.size)
                                } else {
                                    if value.translation.height > 100 {
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                            playerManager.isMinimized = true
                                            setInitialMiniPosition(screenSize: geo.size)
                                            dragOffset = .zero
                                        }
                                    } else {
                                        withAnimation { dragOffset = .zero }
                                    }
                                }
                            }
                    )
                    // TAP PER INGRANDIRE
                    .onTapGesture {
                        if playerManager.isMinimized {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                playerManager.isMinimized = false
                                dragOffset = .zero
                            }
                        }
                    }
                    
                    // 2. TASTO "CHIUDI" SUL MINI PLAYER
                    if playerManager.isMinimized {
                        Button(action: { playerManager.close() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.5).clipShape(Circle()))
                        }
                        .offset(
                            x: (miniOffset.width + dragOffset.width) + miniWidth - 15,
                            y: (miniOffset.height + dragOffset.height) - 15
                        )
                        .transition(.opacity)
                    }
                }
            }
            .allowsHitTesting(playerManager.showPlayer)
        }
        .ignoresSafeArea()
    }
    
    // --- HELPER POSIZIONI ---
    func setInitialMiniPosition(screenSize: CGSize) {
        let x = screenSize.width - miniWidth - 20
        let y = screenSize.height - miniHeight - 100
        miniOffset = CGSize(width: x, height: y)
    }
    
    func snapToBounds(screenSize: CGSize) {
        withAnimation(.spring()) {
            if miniOffset.width < 0 { miniOffset.width = 10 }
            if miniOffset.width > screenSize.width - miniWidth { miniOffset.width = screenSize.width - miniWidth - 10 }
            if miniOffset.height < 50 { miniOffset.height = 50 }
            if miniOffset.height > screenSize.height - miniHeight { miniOffset.height = screenSize.height - miniHeight - 20 }
        }
    }
}

// --- CONTENITORE INTERNO PLAYER ---
struct InnerPlayerContainer: View {
    let url: URL
    let channelName: String
    @ObservedObject var appViewModel: XtreamViewModel
    let isMini: Bool
    
    @StateObject var playerVM = PlayerViewModel()
    @State private var resolvedUrl: URL?
    @ObservedObject var playerManager = PlayerManager.shared
    
    // UI State
    @State private var showControls = true
    @State private var showInfoOverlay = false // <--- NUOVO: Stato Info
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            Color.black
            if let playUrl = resolvedUrl {
                VLCPlayerView(playerViewModel: playerVM, url: playUrl)
                    .onDisappear { playerVM.stop() }
                    .disabled(isMini)
            } else {
                ProgressView().tint(.white)
            }
            
            // --- INFO OVERLAY (PANNELLO STATISTICHE) ---
            if showInfoOverlay && !isMini {
                VStack(alignment: .leading, spacing: 8) {
                    Text("STREAM INFO").font(.caption).bold().foregroundColor(.gray)
                    Divider().background(Color.gray)
                    statRow("Res", playerVM.stats.resolution)
                    statRow("Bitrate", playerVM.stats.bitrate)
                    statRow("Data", playerVM.stats.readBytes)
                    statRow("Lost", "\(playerVM.stats.lostFrames)")
                    statRow("A/V", "\(playerVM.stats.videoCodec)/\(playerVM.stats.audioCodec)")
                }
                .padding()
                .frame(width: 200)
                .superGlass(radius: 15)
                .position(x: 120, y: 200) // Posizionato in alto a sinistra
                .allowsHitTesting(false) // Lascia passare i click
                .transition(.opacity)
            }
            
            // --- CONTROLLI ---
            if !isMini {
                Color.clear.contentShape(Rectangle())
                    .onTapGesture { withAnimation { showControls.toggle() }; resetTimer() }
                
                if showControls {
                    VStack {
                        // HEADER
                        HStack {
                            // Tasto Minimizza
                            Button(action: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    playerManager.isMinimized = true
                                }
                            }) {
                                Image(systemName: "pip.enter").font(.title3).foregroundColor(.white)
                                    .padding(12).background(.ultraThinMaterial).clipShape(Circle())
                            }
                            
                            Spacer()
                            
                            // Titolo
                            Text(channelName).font(.headline).foregroundColor(.white).shadow(radius: 5)
                            
                            Spacer()
                            
                            // --- NUOVO: TASTO INFO ---
                            Button(action: {
                                withAnimation { showInfoOverlay.toggle() }
                                resetTimer()
                            }) {
                                Image(systemName: "info.circle")
                                    .font(.title3).bold()
                                    .foregroundColor(showInfoOverlay ? .green : .white)
                                    .padding(12).background(.ultraThinMaterial).clipShape(Circle())
                            }
                            
                            // Tasto Chiudi
                            Button(action: { playerManager.close() }) {
                                Image(systemName: "xmark").font(.title3).bold().foregroundColor(.white)
                                    .padding(12).background(.ultraThinMaterial).clipShape(Circle())
                            }
                        }
                        .padding(.top, 60)
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        // CONTROLLI BASSO
                        VStack(spacing: 20) {
                            Button(action: { playerVM.togglePlayPause(); resetTimer() }) {
                                Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 50)).foregroundColor(.white).shadow(radius: 10)
                            }
                            HStack {
                                Image(systemName: "speaker.fill").foregroundColor(.white.opacity(0.7))
                                Slider(value: Binding(get: { playerVM.volume }, set: { playerVM.setVolume($0) }), in: 0...1).accentColor(.white)
                            }
                            .padding().background(.ultraThinMaterial).cornerRadius(20).padding(.horizontal, 40)
                        }
                        .padding(.bottom, 60)
                    }
                    .background(Color.black.opacity(0.3)).transition(.opacity)
                }
            }
        }
        .onAppear { performLinkResolution(); if !isMini { resetTimer() } }
        .onChange(of: url) { _ in performLinkResolution() }
    }
    
    // Helper Statistiche
    func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.caption2).foregroundColor(.gray)
            Spacer()
            Text(value).font(.caption2).bold().foregroundColor(.green)
        }
    }
    
    func resetTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in withAnimation { showControls = false } }
    }
    
    func performLinkResolution() {
        let urlString = url.absoluteString
        if urlString.contains(".ts") || urlString.contains(".m3u8") || urlString.contains(".mp4") { self.resolvedUrl = url; return }
        let lastPart = url.lastPathComponent
        if let streamId = Int(lastPart) {
            appViewModel.resolveStalkerLink(streamId: streamId) { realLink in DispatchQueue.main.async { self.resolvedUrl = realLink ?? url } }
        } else { self.resolvedUrl = url }
    }
}
