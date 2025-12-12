import Foundation

extension XtreamViewModel {
    
    // --- HANDSHAKE ---
    func attemptStalkerConnection(baseUrl: String) {
        self.isLoading = true
        var cleanBase = baseUrl
        if cleanBase.hasSuffix("/") { cleanBase.removeLast() }
        // Tentativi intelligenti su path diversi
        let pathsToTry = (cleanBase.hasSuffix("/c") || cleanBase.contains("portal")) ? [cleanBase] : ["\(cleanBase)/c", cleanBase]
        tryNextStalkerPath(paths: pathsToTry, index: 0)
    }
    
    func tryNextStalkerPath(paths: [String], index: Int) {
        if index >= paths.count {
            DispatchQueue.main.async { self.isLoading = false; self.errorMessage = "Errore Stalker: Impossibile connettersi al portale" }
            return
        }
        let currentBaseUrl = paths[index]
        let apiString = "\(currentBaseUrl)/server/load.php"
        guard let url = URL(string: "\(apiString)?type=stb&action=handshake&token=&deviceId=\(macAddress)&deviceId2=\(macAddress)") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("mac=\(macAddress); stb_lang=en; timezone=Europe/Kiev", forHTTPHeaderField: "Cookie")
        request.setValue("Bearer \(macAddress)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 404 {
                    self.tryNextStalkerPath(paths: paths, index: index + 1); return
                }
                guard let data = data, let jsonString = String(data: data, encoding: .utf8) else {
                    self.tryNextStalkerPath(paths: paths, index: index + 1); return
                }
                
                // Se la risposta contiene token o js, siamo dentro
                if jsonString.contains("js") || jsonString.contains("token") {
                    self.isLoggedIn = true; self.serverUrl = currentBaseUrl; self.fetchCategoriesStalker()
                } else {
                    self.tryNextStalkerPath(paths: paths, index: index + 1)
                }
            }
        }.resume()
    }
    
    // --- CATEGORIE ---
    func fetchCategoriesStalker() {
        let urlString = "\(serverUrl)/server/load.php?type=itv&action=get_genres"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.setValue("mac=\(macAddress); stb_lang=en", forHTTPHeaderField: "Cookie")
        request.setValue("Bearer \(macAddress)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                if let response = try? JSONDecoder().decode(StalkerResponse<[StalkerGenre]>.self, from: data), let genres = response.js {
                    self.categories = genres.map { IPTVCategory(categoryId: String($0.id), categoryName: $0.title) }
                } else {
                    // Fallback se le categorie falliscono
                    self.fetchAllStalkerChannels()
                }
            }
        }.resume()
    }
    
    // --- CANALI (Paginazione) ---
    func fetchChannelsStalker(categoryId: String) {
        self.isLoading = true
        self.channels = []
        recursiveStalkerFetch(categoryId: categoryId, page: 1)
    }
    
    func recursiveStalkerFetch(categoryId: String, page: Int) {
        let urlString = "\(serverUrl)/server/load.php?type=itv&action=get_ordered_list&genre=\(categoryId)&force_ch_link_check=&fav=0&sortby=number&hd=0&p=\(page)"
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { self.isLoading = false }
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("mac=\(macAddress); stb_lang=en", forHTTPHeaderField: "Cookie")
        request.setValue("Bearer \(macAddress)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let self = self else { return }
            guard let data = data else { DispatchQueue.main.async { self.isLoading = false }; return }
            
            var pageChannels: [IPTVChannel] = []
            
            // Tentativo 1: Wrapper
            if let response = try? JSONDecoder().decode(StalkerResponse<StalkerWrapper>.self, from: data), let list = response.js?.data {
                pageChannels = list.map { self.mapStalkerToIPTV($0, catId: categoryId) }
            }
            // Tentativo 2: Array Diretto
            else if let response = try? JSONDecoder().decode(StalkerResponse<[StalkerChannel]>.self, from: data), let list = response.js {
                pageChannels = list.map { self.mapStalkerToIPTV($0, catId: categoryId) }
            }
            
            DispatchQueue.main.async {
                if !pageChannels.isEmpty {
                    self.channels.append(contentsOf: pageChannels)
                    self.recursiveStalkerFetch(categoryId: categoryId, page: page + 1)
                } else {
                    self.isLoading = false
                }
            }
        }.resume()
    }
    
    // Helper
    func fetchAllStalkerChannels() {
        let urlString = "\(serverUrl)/server/load.php?type=itv&action=get_all_channels"
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.setValue("mac=\(macAddress); stb_lang=en", forHTTPHeaderField: "Cookie")
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                self.isLoading = false
                guard let data = data else { return }
                if let response = try? JSONDecoder().decode(StalkerResponse<[StalkerChannel]>.self, from: data), let list = response.js {
                    self.allStalkerChannels = list.map { self.mapStalkerToIPTV($0, catId: "0") }
                    self.channels = self.allStalkerChannels
                    self.categories = [IPTVCategory(categoryId: "0", categoryName: "Tutti i Canali")]
                }
            }
        }.resume()
    }
    
    func mapStalkerToIPTV(_ sc: StalkerChannel, catId: String) -> IPTVChannel {
        return IPTVChannel(
            streamId: sc.id, num: nil, name: sc.name ?? "Senza Nome", streamType: "live", streamIcon: sc.logo, categoryId: catId
        )
    }
    
    // --- RISOLUZIONE LINK ---
    func resolveStalkerLink(streamId: Int, completion: @escaping (URL?) -> Void) {
        let urlString = "\(serverUrl)/server/load.php?type=itv&action=create_link&cmd=\(streamId)&series=&forced_storage=0&disable_ad=0&download=0&force_ch_link_check=0&JsHttpRequest=1-xml"
        guard let url = URL(string: urlString) else { completion(nil); return }
        
        var request = URLRequest(url: url)
        request.setValue("mac=\(macAddress); stb_lang=en", forHTTPHeaderField: "Cookie")
        request.setValue("Bearer \(macAddress)", forHTTPHeaderField: "Authorization")
        request.setValue("Mozilla/5.0 (QtEmbedded; U; Linux; C; en-US) AppleWebKit/533.3 (KHTML, like Gecko) MAG200 stbapp ver: 2 rev: 250 Safari/533.3", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else { completion(nil); return }
            
            do {
                let response = try JSONDecoder().decode(StalkerResponse<StalkerLinkResponse>.self, from: data)
                if let rawLink = response.js?.cmd {
                    var cleanLink = rawLink
                        .replacingOccurrences(of: "ffmpeg ", with: "")
                        .replacingOccurrences(of: "ffrt ", with: "")
                        .replacingOccurrences(of: "auto ", with: "")
                        .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    
                    if cleanLink.contains("stream=&") {
                        cleanLink = cleanLink.replacingOccurrences(of: "stream=&", with: "stream=\(streamId)&")
                    }
                    
                    if let finalUrl = URL(string: cleanLink) { completion(finalUrl) } else { completion(nil) }
                } else { completion(nil) }
            } catch { completion(nil) }
        }.resume()
    }
}
