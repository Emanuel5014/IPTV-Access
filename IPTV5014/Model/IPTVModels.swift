import Foundation

// 1. Risposta del Login Xtream
struct XtreamLoginResponse: Codable {
    let userInfo: UserInfo
    let serverInfo: ServerInfo

    enum CodingKeys: String, CodingKey {
        case userInfo = "user_info"
        case serverInfo = "server_info"
    }
}

struct UserInfo: Codable {
    let username: String
    let status: String
    let expDate: String?

    enum CodingKeys: String, CodingKey {
        case username
        case status
        case expDate = "exp_date"
    }
}

struct ServerInfo: Codable {
    let url: String
    let port: String
    let serverProtocol: String
    
    enum CodingKeys: String, CodingKey {
        case url
        case port
        case serverProtocol = "server_protocol"
    }
}

// 2. Modello per le Categorie
struct IPTVCategory: Codable, Identifiable {
    var id: String { categoryId }
    let categoryId: String
    let categoryName: String

    enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
        case categoryName = "category_name"
    }
}

// 3. Modello per i Canali (Aggiornato per M3U)
struct IPTVChannel: Codable, Identifiable {
    var id: Int { streamId }
    let streamId: Int
    let num: AnyCodable?
    let name: String
    let streamType: String
    let streamIcon: String?
    let categoryId: String?
    
    // --- NUOVO CAMPO PER M3U ---
    // Questo campo conterrà l'URL completo del video se stiamo usando una lista M3U
    var videoUrl: String? = nil

    enum CodingKeys: String, CodingKey {
        case streamId = "stream_id"
        case num
        case name
        case streamType = "stream_type"
        case streamIcon = "stream_icon"
        case categoryId = "category_id"
        // Non includiamo 'videoUrl' nei CodingKeys perché Xtream non ce lo manda,
        // lo riempiremo noi manualmente quando analizziamo un file M3U.
    }
}

// Helper per tipi misti (String/Int)
struct AnyCodable: Codable {
    var value: Any
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let x = try? container.decode(Int.self) { value = x }
        else if let x = try? container.decode(String.self) { value = x }
        else { throw DecodingError.typeMismatch(Int.self, .init(codingPath: decoder.codingPath, debugDescription: "Tipo non supportato")) }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let x = value as? Int { try container.encode(x) }
        else if let x = value as? String { try container.encode(x) }
    }
}
