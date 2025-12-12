import Foundation

// Definizioni globali per Stalker - Sendable per Swift 6

struct StalkerResponse<T: Codable>: Codable, Sendable {
    let status: String?
    let js: T?
}

struct StalkerWrapper: Codable, Sendable {
    let data: [StalkerChannel]
}

struct StalkerLinkResponse: Codable, Sendable {
    let cmd: String?
}

struct SafeStringInt: Codable, Sendable {
    let value: String
    var asInt: Int { Int(value) ?? 0 }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            value = String(intVal)
        } else if let strVal = try? container.decode(String.self) {
            value = strVal
        } else {
            value = "0"
        }
    }
}

struct StalkerChannel: Codable, Identifiable, Sendable {
    var id: Int {
        return realID?.asInt ?? ch_id?.asInt ?? Int.random(in: 100000...999999)
    }
    
    let realID: SafeStringInt?
    let ch_id: SafeStringInt?
    let name: String?
    let number: SafeStringInt?
    let logo: String?
    let cmd: String?
    
    enum CodingKeys: String, CodingKey {
        case realID = "id"
        case ch_id
        case name
        case number
        case logo
        case cmd
    }
}

struct StalkerGenre: Codable, Identifiable, Sendable {
    var id: Int { idStr.asInt }
    let idStr: SafeStringInt
    let title: String
    
    enum CodingKeys: String, CodingKey {
        case idStr = "id"
        case title
    }
}
