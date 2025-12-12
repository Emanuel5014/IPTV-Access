import Foundation

extension XtreamViewModel {
    
    func loginM3U() {
        self.isLoading = true
        guard let url = URL(string: serverUrl) else {
            self.errorMessage = "URL non valido"
            self.isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                DispatchQueue.main.async { self.isLoading = false; self.errorMessage = error.localizedDescription }
                return
            }
            
            guard let data = data, let content = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async { self.isLoading = false; self.errorMessage = "Impossibile leggere il file M3U" }
                return
            }
            
            self.parseM3U(content)
            
        }.resume()
    }
    
    func parseM3U(_ content: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            var newChannels: [IPTVChannel] = []
            var tempCategories: Set<String> = []
            
            let lines = content.components(separatedBy: .newlines)
            
            var currentName: String? = nil
            var currentLogo: String? = nil
            var currentGroup: String? = nil
            
            for line in lines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty { continue }
                
                if trimmed.hasPrefix("#EXTINF") {
                    // Nome
                    if let commaIndex = trimmed.lastIndex(of: ",") {
                        currentName = String(trimmed[trimmed.index(after: commaIndex)...]).trimmingCharacters(in: .whitespaces)
                    } else { currentName = "Canale Senza Nome" }
                    
                    // Logo
                    if let logoRange = trimmed.range(of: "tvg-logo=\"") {
                        let rest = String(trimmed[logoRange.upperBound...])
                        if let endQuote = rest.firstIndex(of: "\"") { currentLogo = String(rest[..<endQuote]) }
                    }
                    
                    // Categoria
                    if let groupRange = trimmed.range(of: "group-title=\"") {
                        let rest = String(trimmed[groupRange.upperBound...])
                        if let endQuote = rest.firstIndex(of: "\"") { currentGroup = String(rest[..<endQuote]) }
                    } else { currentGroup = "Non Classificati" }
                    
                } else if !trimmed.hasPrefix("#") {
                    // È URL
                    if let name = currentName {
                        let catName = currentGroup ?? "Generale"
                        tempCategories.insert(catName)
                        
                        let channel = IPTVChannel(
                            streamId: newChannels.count + 1,
                            num: nil,
                            name: name,
                            streamType: "live",
                            streamIcon: currentLogo,
                            categoryId: catName,
                            videoUrl: trimmed
                        )
                        newChannels.append(channel)
                        currentName = nil; currentLogo = nil; currentGroup = nil
                    }
                }
            }
            
            let finalCategories = tempCategories.sorted().map { IPTVCategory(categoryId: $0, categoryName: $0) }
            
            DispatchQueue.main.async {
                self.allM3UChannels = newChannels
                self.categories = finalCategories
                self.isLoggedIn = true
                self.isLoading = false
            }
        }
    }
    
    func fetchChannelsM3U(categoryId: String) {
        self.isLoading = true
        DispatchQueue.global().async {
            let filtered = self.allM3UChannels.filter { $0.categoryId == categoryId }
            DispatchQueue.main.async {
                self.channels = filtered
                self.isLoading = false
            }
        }
    }
}
