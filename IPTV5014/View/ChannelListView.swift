import SwiftUI

struct ChannelListView: View {
    @ObservedObject var viewModel: XtreamViewModel
    let categoryId: String
    let categoryName: String
    
    // --- LINGUA ---
    @ObservedObject var lang = LanguageManager.shared
    
    // Per gestire il ritorno indietro manuale
    @Environment(\.dismiss) var dismiss
    
    @State private var searchText = ""
    
    // Filtro Canali
    var filteredChannels: [IPTVChannel] {
        if searchText.isEmpty {
            return viewModel.channels
        } else {
            return viewModel.channels.filter { channel in
                channel.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
            // 1. SFONDO ANIMATO
            LiquidBackground()
                .onTapToDismissKeyboard() // OK: Toccando lo sfondo vuoto chiude la tastiera
            
            // 2. CONTENUTO
            VStack(spacing: 0) {
                
                // HEADER + SEARCH BAR (Raggruppati per gestire il tocco)
                VStack(spacing: 0) {
                    
                    // HEADER
                    HStack(spacing: 15) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.8))
                                .shadow(radius: 5)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(categoryName)
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)
                            
                            Text("\(filteredChannels.count) \(lang.string(.channels))")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.black.opacity(0.2))
                    
                    // BARRA DI RICERCA
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.5))
                        
                        TextField("", text: $searchText)
                            .placeholder(when: searchText.isEmpty) {
                                 Text(lang.string(.searchCh)).foregroundColor(.white.opacity(0.5))
                            }
                            .foregroundColor(.white)
                            .accentColor(.orange)
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(15)
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    .padding(.horizontal)
                    .padding(.vertical, 15)
                }
                .onTapToDismissKeyboard() // OK: Toccando l'header chiude la tastiera
                
                // LISTA CANALI
                if viewModel.isLoading && viewModel.channels.isEmpty {
                    Spacer()
                    ProgressView(lang.string(.loading))
                        .tint(.white)
                        .scaleEffect(1.2)
                    Spacer()
                } else if filteredChannels.isEmpty {
                    Spacer()
                    VStack(spacing: 15) {
                        Image(systemName: "tv.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.2))
                        Text(lang.string(.noCh))
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .onTapToDismissKeyboard() // OK: Se vuoto, cliccare chiude la tastiera
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredChannels) { channel in
                                if let url = viewModel.getStreamUrl(streamId: channel.streamId) {
                                    Button(action: {
                                        PlayerManager.shared.play(url: url, name: channel.name)
                                    }) {
                                        ChannelRow(channel: channel)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                    .scrollContentBackground(.hidden)
                    // --- FIX CRITICO ---
                    // Invece di usare il TapGesture che blocca i bottoni,
                    // diciamo alla lista di chiudere la tastiera quando si scorre.
                    .scrollDismissesKeyboard(.interactively)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.fetchChannels(categoryId: categoryId)
        }
        // RIMOSSO: .onTapToDismissKeyboard() da qui (causava il blocco)
    }
}

// --- RIGA CANALE (Invariata) ---
struct ChannelRow: View {
    let channel: IPTVChannel
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.4), .purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 45, height: 45)
                    .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                
                Image(systemName: "play.tv.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 18))
                    .shadow(radius: 3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(channel.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack {
                    Text("LIVE")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(4)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            Image(systemName: "play.circle")
                .font(.system(size: 28))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(12)
        .superGlass(radius: 16, opacity: 0.4)
    }
}
