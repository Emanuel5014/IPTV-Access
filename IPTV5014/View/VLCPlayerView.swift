import SwiftUI
import MobileVLCKit

struct VLCPlayerView: UIViewRepresentable {
    @ObservedObject var playerViewModel: PlayerViewModel
    let url: URL

    func makeUIView(context: Context) -> UIView {
        let videoView = UIView()
        videoView.backgroundColor = .black
        videoView.isUserInteractionEnabled = false // Lascia passare i click
        
        // Avvia il player
        playerViewModel.setupPlayer(url: url, view: videoView)
        return videoView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // --- FIX CRITICO ---
        // Se per qualche motivo la vista viene ridisegnata,
        // ci assicuriamo che il player sappia ancora dove disegnare.
        if playerViewModel.mediaPlayer.drawable as? UIView != uiView {
            playerViewModel.mediaPlayer.drawable = uiView
        }
    }
}
