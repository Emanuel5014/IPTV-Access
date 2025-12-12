import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: XtreamViewModel
    
    // --- LINGUA (Osserviamo il manager) ---
    @ObservedObject var lang = LanguageManager.shared

    @State private var playlistName: String = ""
    @State private var serverUrl: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var macAddress: String = "00:1A:79:"
    
    @State private var selectedMode: PlaylistType = .xtream
    @State private var savedPlaylists: [SavedPlaylist] = []
    @State private var editingPlaylistId: UUID? = nil
    @State private var showContent = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topTrailing) { // Allineamento per il tasto lingua
                
                // --- SELETTORE LINGUA (Bandierina Fluttuante) ---
                Menu {
                    Button("🇮🇹 Italiano") { withAnimation { lang.currentLanguage = .it } }
                    Button("🇺🇸 English") { withAnimation { lang.currentLanguage = .en } }
                } label: {
                    Text(lang.currentLanguage.rawValue) // Mostra bandiera attuale
                        .font(.headline)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.2), lineWidth: 1))
                        .shadow(radius: 5)
                }
                .padding(.top, 50) // Spazio dalla safe area
                .padding(.trailing, 30)
                .zIndex(10) // Assicura che stia sopra tutto
                
                // --- CONTENUTO PRINCIPALE ---
                ZStack {
                    if geo.size.width > 900 {
                        HStack(spacing: 40) {
                            loginForm
                                .frame(width: 420)
                                .offset(x: showContent ? 0 : -50, y: 0)
                            
                            savedListsPanel
                                .frame(maxWidth: .infinity)
                                .offset(x: showContent ? 0 : 50, y: 0)
                        }
                        .padding(50)
                        .frame(width: geo.size.width, height: geo.size.height)
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 30) {
                                Spacer().frame(height: 60) // Spazio extra per la bandierina
                                loginForm.frame(maxWidth: 500).offset(y: showContent ? 0 : 50)
                                if !savedPlaylists.isEmpty {
                                    savedListsPanel.frame(maxWidth: 500).offset(y: showContent ? 0 : 100)
                                }
                                Spacer().frame(height: 50)
                            }
                            .padding(.horizontal, 20)
                            .frame(width: geo.size.width)
                            .frame(minHeight: geo.size.height)
                        }
                    }
                }
            }
            .onTapToDismissKeyboard()
        }
        .onAppear {
            loadLists()
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) { showContent = true }
        }
    }
    
    // --- FORM DI LOGIN TRADOTTO ---
    var loginForm: some View {
        VStack(spacing: 25) {
            VStack(spacing: 10) {
                Image(systemName: "tv.and.mediabox")
                    .font(.system(size: 60))
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: .blue.opacity(0.5), radius: 20, x: 0, y: 0)
                
                // USO TRADUZIONE
                Text(editingPlaylistId != nil ? lang.string(.editPlaylist) : lang.string(.appTitle))
                    .font(.largeTitle).bold().foregroundColor(.white)
            }
            .padding(.bottom, 10)
            
            HStack(spacing: 0) {
                modeButton(title: lang.string(.xtream), type: .xtream)
                Divider().background(Color.white.opacity(0.2)).frame(height: 20)
                modeButton(title: lang.string(.stalker), type: .stalker)
                Divider().background(Color.white.opacity(0.2)).frame(height: 20)
                modeButton(title: lang.string(.m3u), type: .m3u)
            }
            .background(Color.black.opacity(0.3)).cornerRadius(15).padding(.bottom, 10)
            
            VStack(spacing: 15) {
                CustomTextField(icon: "pencil", placeholder: lang.string(.listName), text: $playlistName)
                
                let urlPlaceholder: String = {
                    switch selectedMode {
                    case .xtream: return "http://server:port"
                    case .stalker: return "http://portale.com/c/"
                    case .m3u: return "http://sito.com/lista.m3u"
                    }
                }()
                CustomTextField(icon: "link", placeholder: urlPlaceholder, text: $serverUrl)
                
                if selectedMode == .xtream {
                    CustomTextField(icon: "person", placeholder: lang.string(.username), text: $username)
                    CustomTextField(icon: "lock", placeholder: lang.string(.password), text: $password, isSecure: true)
                } else if selectedMode == .stalker {
                    CustomTextField(icon: "macpro.gen3", placeholder: lang.string(.mac), text: $macAddress)
                }
            }
            
            if let error = viewModel.errorMessage {
                Text(error).foregroundColor(.red).font(.caption).padding(5).background(Color.red.opacity(0.1)).cornerRadius(8)
            }
            
            HStack(spacing: 15) {
                if editingPlaylistId != nil {
                    Button(action: resetForm) {
                        Text(lang.string(.cancel)).fontWeight(.bold).foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity).padding().background(Color.white.opacity(0.1)).cornerRadius(15)
                    }
                }
                
                Button(action: handleLoginAndSave) {
                    HStack {
                        if viewModel.isLoading { ProgressView().tint(.white) }
                        else {
                            Text(editingPlaylistId != nil ? lang.string(.update) : lang.string(.login)).fontWeight(.bold)
                            Image(systemName: "arrow.right")
                        }
                    }
                    .foregroundColor(.white).frame(maxWidth: .infinity).padding()
                    .background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(15).shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .disabled(viewModel.isLoading)
            }
        }
        .padding(30).superGlass(radius: 30).opacity(showContent ? 1 : 0)
    }
    
    // --- LISTA SALVATI TRADOTTA ---
    var savedListsPanel: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(lang.string(.yourLists)).font(.title2).bold().foregroundColor(.white).padding(.leading, 10)
            
            if savedPlaylists.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "list.bullet.rectangle.portrait").font(.system(size: 50)).foregroundColor(.white.opacity(0.2))
                    Text(lang.string(.noLists)).foregroundColor(.white.opacity(0.5)).padding(.top)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(savedPlaylists) { playlist in
                            SavedPlaylistRow(playlist: playlist, onPlay: { loadSavedPlaylistForLogin(playlist) }, onEdit: { prepareForEdit(playlist) }, onDelete: {
                                if let index = savedPlaylists.firstIndex(where: { $0.id == playlist.id }) { deleteList(at: IndexSet(integer: index)) }
                            })
                        }
                    }
                    .padding(.horizontal, 5).padding(.bottom, 10)
                }
                .frame(maxHeight: 400)
            }
        }
        .padding(30).superGlass(radius: 30, opacity: 0.5).opacity(showContent ? 1 : 0)
    }
    
    // Helper e Logica invariati (copia dal file precedente, qui metto solo la parte UI)
    func modeButton(title: String, type: PlaylistType) -> some View {
        Button(action: { withAnimation { selectedMode = type } }) {
            Text(title).fontWeight(.bold).font(.footnote)
                .foregroundColor(selectedMode == type ? .white : .gray)
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(selectedMode == type ? Color.white.opacity(0.2) : Color.clear).cornerRadius(15)
        }
    }
    
    // ... INCOLLA QUI LE FUNZIONI DI LOGICA (loadLists, deleteList, ecc.) DAL VECCHIO FILE ...
    // Sono identiche, non serve cambiarle.
    func loadLists() { savedPlaylists = PlaylistManager.shared.loadPlaylists() }
    func deleteList(at offsets: IndexSet) { PlaylistManager.shared.deletePlaylist(at: offsets); loadLists(); if editingPlaylistId != nil { resetForm() } }
    func prepareForEdit(_ p: SavedPlaylist) {
        editingPlaylistId = p.id; playlistName = p.name; serverUrl = p.url; selectedMode = p.type
        if p.type == .xtream { username = p.username ?? ""; password = p.password ?? "" }
        else if p.type == .stalker { macAddress = p.macAddress ?? "" }
    }
    func resetForm() { editingPlaylistId = nil; playlistName = ""; serverUrl = ""; username = ""; password = ""; macAddress = "00:1A:79:" }
    func handleLoginAndSave() {
        let cleanMac = macAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        viewModel.login(url: serverUrl, user: username, pass: password, mac: selectedMode == .stalker ? cleanMac : "", forcedMode: selectedMode)
        if !playlistName.isEmpty {
            if let id = editingPlaylistId { PlaylistManager.shared.updatePlaylist(id: id, name: playlistName, url: serverUrl, type: selectedMode, user: username, pass: password, mac: cleanMac) }
            else { PlaylistManager.shared.savePlaylist(name: playlistName, url: serverUrl, type: selectedMode, user: username, pass: password, mac: cleanMac) }
            loadLists(); resetForm()
        }
    }
    func loadSavedPlaylistForLogin(_ p: SavedPlaylist) {
        if p.type == .xtream { viewModel.login(url: p.url, user: p.username ?? "", pass: p.password ?? "", forcedMode: .xtream) }
        else if p.type == .stalker { viewModel.login(url: p.url, mac: p.macAddress ?? "", forcedMode: .stalker) }
        else { viewModel.login(url: p.url, forcedMode: .m3u) }
    }
}

// Subviews (uguali)
struct CustomTextField: View {
    let icon: String; let placeholder: String; @Binding var text: String; var isSecure: Bool = false
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundColor(.white.opacity(0.7)).frame(width: 20)
            if isSecure { SecureField("", text: $text).placeholder(when: text.isEmpty) { Text(placeholder).foregroundColor(.gray) }.foregroundColor(.white) }
            else { TextField("", text: $text).placeholder(when: text.isEmpty) { Text(placeholder).foregroundColor(.gray) }.foregroundColor(.white).autocapitalization(.none).disableAutocorrection(true) }
        }
        .padding().background(Color.black.opacity(0.3)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

extension View {
    func placeholder<Content: View>(when shouldShow: Bool, alignment: Alignment = .leading, @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) { placeholder().opacity(shouldShow ? 1 : 0); self }
    }
}

struct SavedPlaylistRow: View {
    let playlist: SavedPlaylist; let onPlay: () -> Void; let onEdit: () -> Void; let onDelete: () -> Void
    var typeColor: Color {
        switch playlist.type { case .xtream: return .green; case .stalker: return .orange; case .m3u: return .blue }
    }
    var typeIcon: String {
        switch playlist.type { case .xtream: return "person.fill"; case .stalker: return "server.rack"; case .m3u: return "list.triangle" }
    }
    var body: some View {
        HStack {
            Button(action: onPlay) {
                HStack(spacing: 15) {
                    ZStack { Circle().fill(typeColor.opacity(0.2)).frame(width: 50, height: 50); Image(systemName: typeIcon).foregroundColor(typeColor) }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(playlist.name).font(.headline).foregroundColor(.white)
                        Text(playlist.type.rawValue).font(.caption).padding(.horizontal, 6).padding(.vertical, 2).background(Color.white.opacity(0.1)).cornerRadius(4).foregroundColor(.gray)
                    }
                    Spacer()
                }
            }.buttonStyle(PlainButtonStyle())
            Menu {
                Button(action: onEdit) { Label("Modifica", systemImage: "pencil") }
                Button(role: .destructive, action: onDelete) { Label("Elimina", systemImage: "trash") }
            } label: { Image(systemName: "ellipsis.circle").font(.title2).foregroundColor(.white.opacity(0.6)).padding() }
        }
        .padding(10).background(Color.white.opacity(0.05)).cornerRadius(15)
    }
}
