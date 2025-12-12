import Foundation

extension XtreamViewModel {
    
    func loginXtream() {
        self.isLoading = true
        let loginString = "\(serverUrl)/player_api.php?username=\(username)&password=\(password)"
        guard let requestUrl = URL(string: loginString) else { return }
        
        URLSession.shared.dataTask(with: requestUrl) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                guard let data = data else {
                    self.errorMessage = "Errore di connessione"
                    return
                }
                
                if let response = try? JSONDecoder().decode(XtreamLoginResponse.self, from: data),
                   response.userInfo.status == "Active" {
                    self.isLoggedIn = true
                    self.fetchCategoriesXtream()
                } else {
                    self.errorMessage = "Login fallito: Credenziali errate o scadute"
                }
            }
        }.resume()
    }
    
    func fetchCategoriesXtream() {
        let urlString = "\(serverUrl)/player_api.php?username=\(username)&password=\(password)&action=get_live_categories"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            DispatchQueue.main.async {
                try? self.categories = JSONDecoder().decode([IPTVCategory].self, from: data)
            }
        }.resume()
    }
    
    func fetchChannelsXtream(categoryId: String) {
        let urlString = "\(serverUrl)/player_api.php?username=\(username)&password=\(password)&action=get_live_streams&category_id=\(categoryId)"
        guard let url = URL(string: urlString) else { return }
        
        self.isLoading = true
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                self.isLoading = false
                guard let data = data, let list = try? JSONDecoder().decode([IPTVChannel].self, from: data) else { return }
                self.channels = list
            }
        }.resume()
    }
}
